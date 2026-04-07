# Lab Walkthroughs — Complete Answers

---

## Lab 01 — Traffic Baselining

### Dataset: eve_sample.jsonl (5 events, 2026-02-26)

#### Event Classification

| # | Type | Source | Destination | Classification | Reasoning |
|---|------|--------|-------------|----------------|-----------|
| 1 | flow (TCP/TLS) | 10.10.1.10 | 1.1.1.1 | **Benign** | Internal host connecting to Cloudflare DNS (1.1.1.1) over TLS, 12/14 packets exchanged = completed session |
| 2 | dns | 10.10.1.10 | 10.10.0.53 | **Benign** | Internal host querying internal DNS resolver for `updates.example.org` — routine update check |
| 3 | alert sev-2 | 203.0.113.44 | 10.10.1.20 | **Suspicious** | External IP using Nmap NSE User-Agent — active reconnaissance, confirm scope/intent |
| 4 | alert sev-1 | 198.51.100.9 | 10.10.1.20 | **High Priority** | External IP probing CVE pattern against same internal host — possible exploitation attempt |
| 5 | http | 10.10.1.20 | 198.51.100.25 | **Needs More Evidence** | Internal host GETting `/packages/index.json` from `repo.example.edu` — apt update traffic; note: same host (10.10.1.20) targeted in sev-1 alert |

#### Analyst Summary

**Signal vs Noise:**
- 2 alerts (sev-1 and sev-2), 3 informational events (1 flow, 1 DNS, 1 HTTP)
- Sev-1 is priority: `198.51.100.9 → 10.10.1.20` with CVE probe pattern
- Sev-2 (Nmap scan) from **different** external IP (`203.0.113.44`) — likely separate actor or scan infrastructure

**Risk Assessment:**
- `10.10.1.20` is the focal point: targeted by external scan (sev-2), CVE probe (sev-1), and also initiating outbound HTTP (event 5)
- The outbound HTTP from `10.10.1.20` to `198.51.100.25` (event 5) needs correlation: is `198.51.100.25` related to `198.51.100.9`? (Same /24 subnet — investigate)

**Prioritization Order:**
1. Investigate sev-1 (CVE probe, `10.10.1.20`) — potential active exploitation
2. Check if `198.51.100.9` and `198.51.100.25` are the same actor (same subnet)
3. Review sev-2 (Nmap scan) — likely recon precursor to sev-1
4. Event 5 (outbound HTTP) — monitor; benign if apt update confirmed

**Next Actions:**
- Pull full pcap for `10.10.1.20` in the time window around events 3, 4, 5
- Check if `10.10.1.20` made any connections to `198.51.100.9` or `198.51.100.25` after the CVE probe
- Verify `repo.example.edu` resolves to a known-good update repository
- Check endpoint logs on `10.10.1.20` for process activity around the same timestamp

---

## Lab 02 — Suricata Detection Tuning

### Scenario: INC-002 — Noisy Rule on apt Update Traffic

#### Tuning Hypothesis
> The rule triggering on `repo.example.edu` apt update traffic (event 5 in eve_sample.jsonl) is generating false positives because it matches the HTTP GET to `/packages/index.json` by package manager user-agent or URL pattern, without distinguishing legitimate update servers from actual attack traffic.

#### Proposed Tuning Change
Scope the rule to exclude known-good package repository servers by:
1. Adding a `threshold` keyword: require ≥3 hits from same source in 60s before alerting
2. Or adding a `content:!"repo.example.edu"` negation to the HTTP host match
3. Document the server list in `triage_rules.yaml` as analyst reference

#### Success Metrics (pre-define before making change)
| Metric | Baseline | Target After Tuning |
|--------|----------|---------------------|
| Alerts from apt update traffic | X per day | 0 (completely suppressed for known servers) |
| Sev-1 alerts in same rule category | N per day | N unchanged (no regression) |
| Analyst review time on this rule | Y minutes/day | <50% of baseline |

#### Protected Categories (never tune down)
- `severity_1: critical` alerts — no threshold reduction, no exception
- `classtype:attempted-priv-escalation` — always fire on first match
- Any rule matching known CVE exploitation patterns

#### Rollback Triggers
- If any sev-1 alert is missed within 48h of the tuning change → immediate revert
- If alert volume drops >60% (possible rule breakage, not just tuning) → investigate
- If a new CVE probe from the same category appears and doesn't alert → revert

#### Rollback Procedure
```bash
git revert HEAD  # revert configs/triage_rules.yaml change
# or restore from known-good backup:
cp configs/triage_rules.yaml.backup configs/triage_rules.yaml
# Re-validate:
bash labs/lab_02_suricata_detection_tuning/validation_script.sh
```

---

## Lab 03 — TLS Handshake Forensics

### Scenario: INC-003 — Research Workstation TLS Certificate Anomaly

#### Multiple Hypotheses (enumerate before investigating)

| Hypothesis | Likelihood | Evidence Needed to Confirm/Reject |
|------------|-----------|-----------------------------------|
| Enterprise TLS inspection proxy | High | Check if proxy CA is in workstation trust store; confirm other workstations show same cert |
| Lab PKI / self-signed cert | High | Check cert issuer against lab CA list; confirm cert used on other internal services |
| CDN/third-party cert rotation | Medium | Check certificate transparency logs for this domain; verify new cert is from known CA |
| MITM attack (rogue CA) | Low-Medium | Cert issued by unknown CA not in trust store; no proxy configured; hostname mismatch unexplained |
| Compromised workstation | Low | Endpoint indicators needed: unusual processes, network connections, auth logs |

#### Evidence Collection Steps (in order, before any containment)

1. **Certificate chain**: export full chain — who issued the intermediate, who issued the root
2. **Hostname validation**: does the certificate SAN match the hostname being accessed?
3. **Trust store check**: is the issuing CA in the workstation's trusted root store?
4. **Endpoint context**: is a corporate proxy configured? (`proxy.pac`, browser proxy settings, system proxy)
5. **Corroboration**: do other workstations on the same network show the same cert for the same destination?
6. **CT log check**: is this certificate visible in public Certificate Transparency logs (crt.sh)?

#### Minimum Evidence Before Containment Decision
- Certificate chain fully documented (issuer, validity, SAN, fingerprint)
- Trust store membership confirmed or denied
- Proxy configuration checked
- At least one corroborating data point (another host, CT log, network flow)

#### Decision Tree
```
Unknown CA in cert chain
    ├── CA is in workstation trust store
    │   └── Likely enterprise proxy or lab PKI → document, no containment
    ├── CA NOT in trust store + proxy configured for this traffic
    │   └── Proxy misconfiguration → fix proxy CA distribution
    └── CA NOT in trust store + no proxy + unique to this workstation
        └── HIGH RISK: isolate workstation, escalate, collect full forensic image
```

#### Common Analysis Errors
- Treating any cert mismatch as compromise without checking proxy config
- Not checking if other hosts show the same cert (corroboration)
- Recommending containment before the certificate chain is fully documented

---

## Lab 04 — Zero Trust Segmentation Policy

### Scenario: Based on INC-001 Suspicious Scan (203.0.113.44 → 10.10.1.20)

#### Trust Boundary Design

**Assets requiring protection:**
- `10.10.1.20` — internal server (targeted in scan + CVE probe)
- Internal subnet `10.10.1.0/24` — production hosts
- `10.10.0.53` — internal DNS resolver

**Proposed Boundaries:**
```
Internet → [Perimeter Firewall] → DMZ (10.10.2.0/24)
DMZ → [Internal Firewall] → Production (10.10.1.0/24)
Production → [Micro-segmentation] → Individual services
```

#### Service Dependency Catalog

| Service | Host | Allowed Sources | Protocol/Port | Business Reason |
|---------|------|----------------|---------------|-----------------|
| DNS resolution | 10.10.0.53 | 10.10.1.0/24 | UDP/53, TCP/53 | Name resolution for all internal hosts |
| Package updates | 10.10.1.20 | repo.example.edu (IP) | TCP/443 | apt package manager |
| TLS external | 10.10.1.10 | 1.1.1.1 | TCP/443 | DNS-over-HTTPS or CDN |
| Management | 10.10.1.20 | Admin segment only | TCP/22 | SSH administration |

#### Access Policy Decisions

```yaml
# Default: deny all inbound from internet to 10.10.1.0/24
# Exceptions must be explicit and logged

policy:
  inbound_internet:
    default: DENY
    log: all

  outbound_production:
    allow:
      - dest: 10.10.0.53, port: 53, protocol: UDP/TCP, reason: "DNS"
      - dest: repo.example.edu, port: 443, protocol: TCP, reason: "package updates"
    default: DENY
    log: all denied + all allowed to external destinations

  admin_access:
    allow:
      - src: admin_segment, dest: 10.10.1.20, port: 22, protocol: TCP
    require: MFA + logging
    default: DENY
```

#### Logging Requirements
- Every allow/deny decision logged with: src IP, dst IP, port, protocol, rule matched, timestamp
- Authentication events logged: who accessed what admin service, from where, when
- Policy change events logged with: who made the change, what changed, approval reference

#### Validation Steps
1. Confirm `10.10.1.20` still receives DNS responses after policy deployment
2. Confirm `10.10.1.20` can reach `repo.example.edu:443` for apt updates
3. Confirm `203.0.113.44` (attacker IP from INC-001) is blocked at perimeter
4. Confirm SSH access works from admin segment, blocked from all other sources
5. Review logs: confirm deny decisions are appearing for simulated attack traffic

#### Rollback Procedure
```
Known-good state: policy before deployment
Rollback trigger: any legitimate service breaks within 2h of deployment
Rollback steps:
  1. Identify breaking rule from logs
  2. Add explicit exception with time-bounded approval
  3. Schedule permanent fix within 24h
  4. Document in exception register
```
