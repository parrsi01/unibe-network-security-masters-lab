# Network Security Foundation Lab — Full Study Notes

---

## Module 1: Foundations — Network Security Fundamentals

### Key Concepts

**Attack Surface Mapping**
The total set of points where an adversary can attempt to enter or extract data from an environment. Includes:
- Network interfaces (all IPs, ports, protocols)
- Service endpoints (web apps, APIs, admin panels)
- Trust boundaries between network segments
- Data flows between systems

**Trust Boundaries**
Logical or physical lines where the security assumption changes. Crossing a trust boundary should require authentication, authorization, and logging. Common boundaries: internet → DMZ, DMZ → internal, user segment → admin segment, corporate → cloud.

**Asset Inventory & Data Flow Validation**
You cannot protect what you don't know exists. Asset inventory must include:
- IP addresses and hostnames
- Services and ports in use
- Data classification per asset (PII, credentials, operational)
- Who communicates with what (data flow map)

**Observability Requirements**
To detect and respond to attacks you need telemetry at every trust boundary:
- Packet-level: tcpdump, Zeek, Suricata
- Flow-level: NetFlow, IPFIX, sFlow
- Log-level: syslog, auth logs, application logs

### Why It Matters
You can't write detection rules for traffic you haven't baselined. You can't segment what you haven't mapped. Every downstream security operation depends on accurate asset inventory and observability.

### Common Mistakes
| Mistake | Consequence |
|---------|-------------|
| Scanning only active assets | Shadow IT and rogue devices missed |
| Assuming firewall = trust boundary | Lateral movement goes undetected |
| No data flow baseline | Normal vs anomalous impossible to distinguish |
| Observability gaps at boundaries | Attacks transit silently |

### Practical Analyst Checklist
- [ ] Can you list every IP and service in scope?
- [ ] Do you have packet capture capability at each boundary?
- [ ] Is your asset inventory updated after each network change?
- [ ] Do you have a baseline of normal traffic volume and protocols?

---

## Module 2: Protocol Security — Protocol Abuse Patterns

### Key Concepts

**DNS Tunneling / Covert Signaling**
DNS allows exfiltration because UDP/53 is almost never blocked outbound. Attackers encode data in subdomains:
- `c2-data.attackerdomain.com` — each query carries payload
- High query rate, long subdomain strings, unusual TLD usage
- Defenders look for: query rate per client, subdomain entropy, unusual record types (TXT, NULL)

**HTTP Header Anomalies**
HTTP headers carry metadata attackers abuse:
- `User-Agent` fingerprinting for targeting (knowing the victim's browser/OS)
- `X-Forwarded-For` manipulation to bypass IP-based controls
- Custom headers used as C2 channel (encoded instructions)
- Staged delivery via `Range` headers to evade content inspection

**TLS SNI / JA3 Metadata Misuse**
TLS encrypts payload but not metadata:
- SNI (Server Name Indication) reveals the destination hostname even in encrypted traffic
- JA3 fingerprints the TLS client hello (ciphersuites, extensions, elliptic curves) — useful for identifying malware families without decrypting
- Certificate subject/issuer visible in handshake — defenders can detect self-signed or suspicious CAs

**TCP Handshake / Timing Patterns**
- SYN flood: high rate of SYN packets with no corresponding ACK — resource exhaustion or scanner
- Half-open connections: never complete the three-way handshake
- Port scan signatures: sequential port access, multiple ports per second, Nmap NSE User-Agent in HTTP

### Why It Matters
Attackers operate within legitimate protocols to blend with normal traffic. Detection requires understanding what normal looks like at the protocol level — syntax can be valid while semantics are malicious.

### Common Mistakes
| Mistake | Consequence |
|---------|-------------|
| Only inspecting payload | Protocol-level abuse in headers/metadata missed |
| Blocking all unusual DNS | Legitimate services (CDN, cloud) disrupted |
| Trusting JA3 alone for attribution | JA3 collisions across legitimate/malicious clients |
| No TLS metadata logging | Encrypted C2 channels invisible |

### Practical Analyst Checklist
- [ ] Is DNS query volume per client baselined?
- [ ] Are JA3 fingerprints logged for TLS connections?
- [ ] Is SNI logged for all TLS flows?
- [ ] Are HTTP User-Agent strings monitored for known scanner signatures?

---

## Module 3: Crypto & TLS — Operational Security

### Key Concepts

**Certificate Validation Chain**
Every TLS certificate must chain to a trusted root CA:
1. Server presents certificate
2. Client verifies signature against intermediate CA
3. Intermediate CA chains to root CA in trust store
4. Root CA is pre-installed in OS/browser

Breaks at any link = certificate error. Common causes: expired cert, wrong hostname, self-signed, untrusted CA.

**TLS Handshake Metadata Useful to Defenders**
Even without decrypting content, defenders can extract:
- SNI: destination hostname
- Certificate subject/SAN/issuer: who issued it, is it a known CA
- JA3/JA3S: client and server TLS fingerprints
- Cipher suite: whether strong ciphers are used or weak (export-grade)
- Certificate validity period and transparency log presence

**Limits of Payload Inspection Under Encryption**
- TLS 1.3 encrypts more of the handshake than TLS 1.2
- Enterprise TLS inspection (MITM proxy) can decrypt but introduces its own risks (new CA in trust store, performance)
- Detection without decryption relies entirely on metadata: flow patterns, certificate properties, behavioral signals

**Operational Tradeoffs**
| Approach | Visibility | Privacy | Complexity |
|----------|-----------|---------|------------|
| No inspection | Metadata only | High | Low |
| TLS interception proxy | Full payload | Low | High |
| Certificate pinning (apps) | N/A | High | Medium |
| JA3 + SNI logging | Metadata | High | Low |

### Why It Matters
Most enterprise traffic is TLS. If you can't operate within encrypted traffic constraints, you're blind to the majority of network activity. Metadata-based detection is the practical answer.

### Common Mistakes
| Mistake | Consequence |
|---------|-------------|
| Treating cert error = compromise | Enterprise proxies cause cert mismatches routinely |
| Ignoring certificate transparency logs | CT log anomalies indicate new/suspicious certs |
| Assuming TLS = safe | Malware uses TLS too; encryption ≠ legitimacy |
| Deploying TLS inspection without policy | Breaks cert pinning in apps, legal/privacy exposure |

### Practical Analyst Checklist
- [ ] Are TLS certificate details (issuer, SAN, validity) logged?
- [ ] Is JA3 fingerprinting enabled in Suricata/Zeek?
- [ ] Is there a documented list of known enterprise proxy CAs?
- [ ] Are self-signed certs in production investigated?

---

## Module 4: Detection Engineering — Suricata & IDS Tuning

### Key Concepts

**Detection as Software Engineering**
Detection rules are code. They must be:
- **Versioned**: in git with meaningful commit messages
- **Tested**: against sample data before deployment
- **Tuned**: with evidence-based metrics, not instinct
- **Reviewed**: like PRs, by a second analyst

**Suricata Tuning Loop**
```
Define objective (what behavior to detect)
    ↓
Baseline event volume (how many alerts firing, over what timeframe)
    ↓
Review false positives with evidence (pcap, logs, endpoint context)
    ↓
Adjust thresholds/scope/rule selection (one change at a time)
    ↓
Re-validate: detection coverage still intact? Analyst workload acceptable?
    ↓
Document: hypothesis, change made, metrics before/after, rollback condition
```

**Key Metrics**
| Metric | Good | Concern |
|--------|------|---------|
| Alert rate (per day) | Stable baseline | >20% unexplained increase |
| False positive rate | <15% of analyst time on FPs | >30% = tuning required |
| True positive rate | Consistent with threat intel | Drop = evasion or rule breakage |
| Time to triage per alert | Under analyst SLA | Rising = noise problem |

**Rollback Criteria**
Always define before tuning: "If we miss a sev-1 detection within 48 hours of this change, we revert."

### Rule Anatomy (Suricata)
```
alert tcp $EXTERNAL_NET any -> $HOME_NET $HTTP_PORTS (
    msg:"ET SCAN Nmap Scripting Engine User-Agent Detected";
    content:"Nmap Scripting Engine";
    http_user_agent;
    classtype:attempted-info-leak;
    sid:2009358;
    rev:3;
)
```

Components: action, protocol, src/dst network, src/dst port, options (msg, content match, classtype, sid, rev).

### Why It Matters
Noisy rules erode analyst trust. Analysts start ignoring alerts. High-severity detections are missed because they're buried in noise. Detection quality directly determines incident response effectiveness.

### Common Mistakes
| Mistake | Consequence |
|---------|-------------|
| Tuning based on annoyance, not metrics | Reduced coverage, undefined tradeoffs |
| Disabling rules without preserving logic | Coverage gap with no documentation |
| No rollback condition defined | Can't revert safely when issues arise |
| Treating all severities equally | Sev-1 buried under sev-4 noise |

### Practical Analyst Checklist
- [ ] Do you have alert volume baseline for each rule category?
- [ ] Is each tuning change documented with before/after metrics?
- [ ] Are rollback conditions defined for every tuning decision?
- [ ] Are sev-1 rules treated as protected (no threshold reduction)?

---

## Module 5: Network Forensics — Workflow

### Key Concepts

**5-Step Forensics Workflow**
1. **Triage alert**: what fired, what is the signature/category, what is the severity
2. **Preserve telemetry**: pcap, logs, timestamps — before any remediation action
3. **Build time-ordered timeline**: reconstruct events in sequence using multiple log sources
4. **Correlate hosts/services/identities**: which IPs, hostnames, users, services are involved
5. **Produce conclusion with confidence level and gaps**: "High confidence this is X based on Y evidence; unknown: Z"

**Evidence Preservation**
Before touching a potentially compromised system:
- Capture full packet trace (if live) or preserve existing pcap
- Export logs with timestamps (preserve timezone context)
- Document the chain of custody: who collected, when, from where
- Hash the evidence files (SHA-256) for integrity verification

**Timeline Reconstruction**
Correlate events across:
- IDS/Suricata alerts (timestamp, rule, src/dst)
- DNS logs (what was resolved, by whom, when)
- Flow records (connection duration, bytes, protocol)
- Endpoint logs (process, user, file access — if available)

**Confidence Levels**
Always state confidence explicitly:
- **High confidence**: multiple independent evidence sources agree
- **Medium confidence**: single evidence source with plausible benign explanation
- **Low confidence**: circumstantial or incomplete evidence
- **Unknown**: evidence gap, explicitly state what's missing

### Why It Matters
Conclusions without stated confidence lead to incorrect containment decisions. Containment before evidence collection can destroy evidence. Timeline reconstruction is the difference between a resolved incident and an ongoing one.

### Common Mistakes
| Mistake | Consequence |
|---------|-------------|
| Remediating before preserving evidence | Evidence destroyed, root cause unknown |
| Treating alerts as facts | High FP rate means alerts are hypotheses, not conclusions |
| Ignoring time zone in timestamps | Timeline reconstruction fails |
| Single-source conclusions | Correlated evidence required for high confidence |

### Practical Analyst Checklist
- [ ] Is telemetry preserved before any containment action?
- [ ] Is the timeline reconstructed from ≥2 independent log sources?
- [ ] Is confidence level explicitly stated in the conclusion?
- [ ] Are evidence gaps explicitly documented?

---

## Module 6: Zero Trust — Segmentation and Policy Verification

### Key Concepts

**Zero Trust Principles**
- Never trust, always verify
- Assume breach: design as if the attacker is already inside
- Least privilege: minimum access required to function
- Verify explicitly: authenticate and authorize every request

**Why Zero Trust Fails in Practice**
Policy intent ≠ policy enforcement. Common failure modes:
- Policy designed without mapping service dependencies
- Emergency access exceptions never reviewed or revoked
- Logging not capturing decision context (who, what, when, why)
- No tested rollback path for policy changes

**Verification Requirements**
Before deploying segmentation policy, verify:
1. **Identity assumptions**: does the policy rely on IP-based identity? Can those IPs be spoofed?
2. **Network path assumptions**: have you confirmed traffic actually flows through the policy enforcement point?
3. **Service dependency exceptions**: does "deny all" break a legitimate service dependency you haven't mapped?
4. **Logging and decision visibility**: can you confirm the policy is being evaluated for real traffic?
5. **Emergency rollback**: if this policy breaks production, can you revert in <5 minutes?

**Segmentation Design Process**
```
Enumerate assets → Classify by sensitivity → Map dependencies
    ↓
Define trust boundaries → Assign identity (certificates > IP)
    ↓
Write explicit allow rules → Default deny everything else
    ↓
Test: confirm allowed traffic flows → confirm denied traffic is blocked
    ↓
Document: policy intent, dependency map, exception log, rollback procedure
```

### Why It Matters
Segmentation is only effective if it's verified against real traffic. Paper policies that haven't been tested against production dependencies fail at the worst time.

### Common Mistakes
| Mistake | Consequence |
|---------|-------------|
| Designing deny rules without dependency map | Legitimate services break at deployment |
| Missing logging requirements | Can't audit access decisions |
| No rollback sequence | Emergency access breaks production |
| Trusting IP addresses as identity | IP spoofing bypasses policy |

### Practical Analyst Checklist
- [ ] Is every service dependency documented before segmentation?
- [ ] Is there a tested rollback procedure?
- [ ] Does the policy enforcement point log every allow/deny decision?
- [ ] Are emergency exceptions time-bounded and reviewed?

---

## Module 7: Research Methods — Experimental Design

### Key Concepts

**Research Question → Hypothesis → Experiment**
Never tune or change a detection without a pre-defined hypothesis:
- What behavior do I expect to change?
- How will I measure it?
- What result would falsify my hypothesis?

**Variables**
- **Independent**: what you're changing (rule threshold, alert scope, time window)
- **Dependent**: what you're measuring (alert rate, analyst review time, missed detections)
- **Controls**: what you're holding constant (traffic volume, rule set, environment)
- **Confounders**: external factors that could explain your results (network traffic spike, new deployment)

**Documenting an Experiment**
```markdown
## Hypothesis
Reducing the SYN scan threshold from 100 to 50 packets/second will reduce
false positives by 30% without missing true positive scans.

## Method
Run modified threshold against 7 days of historical eve.json data.
Count alerts per rule, compare to baseline.

## Controls
Same traffic data, same environment, only threshold changed.

## Success Criteria
- FP rate reduced ≥25%
- No sev-1 alerts missed that were caught by original rule
- Alert volume reduction <50% (to avoid coverage gap risk)

## Rollback
Revert if: any sev-1 scan alert missed within 24h of deployment.
```

### Why It Matters
Without experimental discipline, tuning decisions are guesses. Guesses accumulate into coverage gaps. Detection regression is invisible without pre-defined metrics.

### Common Mistakes
| Mistake | Consequence |
|---------|-------------|
| No pre-defined success criteria | Can't tell if tuning worked |
| No control period | Can't attribute change to your action |
| Changing multiple variables at once | Can't identify which change caused the effect |
| No limitations section | Consumers of results don't know scope/validity |

---

## Quick Reference — Analyst Questions

Before any investigation:
1. What is the alert/symptom?
2. Which hosts are involved?
3. What is the time window?
4. What protocol/service?
5. What evidence is available?
6. What evidence is missing?
7. What is the next safe action?

Before any tuning decision:
1. What is the baseline alert volume?
2. What evidence supports this change?
3. What are the success metrics?
4. What is the rollback condition?
5. What detection coverage is at risk?
