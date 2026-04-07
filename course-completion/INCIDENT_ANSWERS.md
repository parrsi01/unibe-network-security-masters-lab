# Incident Ticket Model Answers

---

## INC-001 — Suspicious Scan

**Ticket Summary:** IDS generated repeated scan alerts targeting `10.10.1.20` from external IP `203.0.113.44`.

### Evidence Used
- `eve_sample.jsonl` event 3: `alert`, severity-2, signature "ET SCAN Nmap Scripting Engine User-Agent Detected", `classtype:attempted-info-leak`, `203.0.113.44 → 10.10.1.20`
- Correlated with event 4: separate sev-1 CVE probe from different IP (`198.51.100.9 → 10.10.1.20`) — suggests `10.10.1.20` is a target of interest

### Assessment
External host `203.0.113.44` is conducting active reconnaissance against `10.10.1.20` using Nmap Scripting Engine. This is confirmed scanning activity, not passive monitoring or legitimate traffic. The Nmap NSE User-Agent is a definitive indicator of active probing.

**Key distinction:** This is recon (information gathering), not exploitation. The sev-2 classification is appropriate. However, the separate sev-1 CVE probe from `198.51.100.9` in the same time window targeting the same host changes the risk picture — the target (`10.10.1.20`) appears to be actively targeted by multiple actors.

### Recommended Next Actions
1. **Monitor** `10.10.1.20` for any outbound connections to `203.0.113.44` or `198.51.100.9` (would indicate successful exploitation)
2. **Pull extended pcap** for `10.10.1.20` ±10 minutes around the alert timestamps
3. **Investigate `198.51.100.9`** (same /24 as event 5 HTTP destination `198.51.100.25`) — determine if same threat actor
4. **Containment threshold**: if scan escalates to exploitation attempt (sev-1 from `203.0.113.44`) or if `10.10.1.20` makes unexpected outbound connections → escalate to immediate containment

### Evidence Used for Conclusion
- EVE alert event (signature, classification, src/dst IPs confirmed)
- Severity classification from Suricata rule (sev-2 = intended-info-leak, not yet exploitation)
- Correlated timeline with sev-1 event (same target, different actor, same timeframe)

**Confidence: High** — Nmap NSE User-Agent is definitively malicious/scanning; source IP and target confirmed in telemetry.

---

## INC-002 — Noisy IDS Rule

**Ticket Summary:** IDS rule firing on routine `apt` update traffic, reducing analyst confidence in alert queue.

### Evidence Used
- `eve_sample.jsonl` event 5: HTTP GET `/packages/index.json` from `10.10.1.20` to `repo.example.edu` with apt user-agent
- `configs/triage_rules.yaml`: current severity classifications
- Pattern: routine software update behavior triggering a detection rule not intended for this traffic

### Root Cause
The rule's match criteria are too broad — they trigger on any HTTP GET to a URL matching `/packages/index.json` regardless of:
- Known-good source (internal `10.10.1.20` making an outbound update request)
- Known-good destination (`repo.example.edu` — a package repository)
- Known-good user-agent (apt package manager, not attacker tooling)

**The rule is catching legitimate traffic that shares syntactic patterns with what it was designed to detect.**

### Tuning Proposal
**Option A (recommended):** Add destination allowlist — exclude known package repository FQDNs from this rule
**Option B:** Add user-agent allowlist — exclude known package manager user-agents (apt, yum, dnf)
**Option C:** Raise threshold — require >5 requests in 60s before alerting (burst detection)

For each option, document: exact rule change, validation dataset, success metrics, rollback trigger.

### Success Metrics
- Alert volume from this rule reduced to 0 for documented update servers
- Sev-1 alerts in same rule category: unchanged (no regression)
- Time period for validation: 7 days post-change
- Analyst review time on this rule: tracked before and after

### Rollback Criteria
- Any sev-1 detection missed in the same rule category within 48h → immediate revert
- Total alert volume from this rule drops >80% (over-suppression risk) → investigate
- New update server appears that triggers rule → add to allowlist (not rollback)

---

## INC-003 — TLS Certificate Anomaly

**Ticket Summary:** Research workstation shows TLS connection with unexpected certificate chain and hostname mismatch.

### Evidence Collection (pre-analysis, before conclusions)

Collect all of the following before drawing any conclusion:
1. **Certificate chain export**: full chain (leaf → intermediate → root), fingerprints, issuer CN, validity period
2. **SAN vs hostname**: what hostnames are in the SAN/CN fields, does the connection hostname match
3. **Trust store check**: is the issuing CA in the workstation's OS trust store
4. **Proxy configuration**: is a corporate TLS inspection proxy configured for this workstation
5. **Network context**: do other workstations on the same network show the same cert for the same destination
6. **CT log**: query crt.sh for this domain — is this cert in public Certificate Transparency logs

### Benign Causes (investigate first)
| Cause | How to Confirm |
|-------|---------------|
| Enterprise TLS inspection proxy | Proxy CA in trust store; other hosts affected; IT confirms proxy deployment |
| Lab PKI (self-signed) | Issuer matches lab CA; expected in lab environment documentation |
| CDN certificate rotation | CT log shows cert is new but issued by trusted CA; legitimate domain |
| Misconfigured certificate (wrong cert on server) | Cert issuer is legitimate CA but SAN doesn't include this domain; server config error |

### Malicious Causes (escalate if evidence points here)
| Cause | Indicators |
|-------|-----------|
| MITM attack (rogue CA) | CA not in trust store, not a known proxy, unique to this workstation |
| Compromised certificate authority | CA is known but certificate is anomalous in other ways |
| TLS stripping with cert replacement | Connection downgraded + new cert installed mid-session |

### Minimum Evidence Before Containment
Do NOT contain the workstation until ALL of the following are checked:
- [ ] Certificate chain fully documented
- [ ] Trust store membership confirmed or denied
- [ ] Proxy configuration verified
- [ ] Other workstations checked for same cert (corroboration)

**Rationale:** Containment is disruptive. Enterprise TLS proxies cause cert anomalies on 100% of workstations — containing all of them would be incorrect and damaging. The evidence threshold exists to prevent false-positive containment.

### Recommended Next Steps (ordered)
1. Ask IT: "Is there a TLS inspection proxy deployed? Which CA does it use?"
2. Export full cert chain from the workstation's browser/OS
3. Check the issuing CA against the trust store and known proxy CA list
4. If proxy confirmed → close ticket, document as expected behavior
5. If no proxy and CA is unknown → isolate workstation, escalate, forensic image

**Confidence: Medium** — Without proxy/CA context, cannot determine if benign or malicious. Confidence will move to High once proxy configuration is confirmed or ruled out.
