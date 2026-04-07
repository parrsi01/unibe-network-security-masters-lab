# Competency Map — Skills to Repo Evidence

---

## Detection Engineering

| Skill | Demonstrated In | CV Bullet |
|-------|----------------|-----------|
| Suricata EVE log parsing | `scripts/analyze_suricata_eve_sample.py` | Built Python-based Suricata EVE triage tool processing JSONL log streams with automated severity classification |
| Alert triage prioritization | `labs/lab_01_traffic_baselining/`, `incidents/tickets/` | Triaged multi-event IDS alert queues, correlating severity levels and source/destination pairs to identify exploitation precursors |
| Detection rule tuning | `labs/lab_02_suricata_detection_tuning/`, `configs/triage_rules.yaml` | Developed evidence-based tuning proposals with pre-defined success metrics and rollback criteria |
| Detection as software engineering | `tests/test_suricata_triage.py`, CI/CD pipeline | Implemented automated regression tests for detection logic; maintained detection content in version control with CI validation |

---

## Protocol & Transport Security

| Skill | Demonstrated In | CV Bullet |
|-------|----------------|-----------|
| TLS metadata analysis | `labs/lab_03_tls_handshake_forensics/`, `docs/crypto_and_tls/` | Analyzed TLS certificate chains and handshake metadata to triage certificate anomalies without payload decryption |
| Protocol abuse pattern recognition | `docs/protocol_security/protocol_abuse_patterns.md` | Documented detection approaches for DNS tunneling, HTTP header abuse, and TCP scanning patterns |
| Encrypted traffic analysis | `Library/03_tls_and_crypto_operational_security.md` | Applied metadata-based detection techniques (JA3, SNI, certificate validation) for security analysis under TLS encryption |

---

## Network Forensics & Incident Response

| Skill | Demonstrated In | CV Bullet |
|-------|----------------|-----------|
| Structured incident triage | `incidents/tickets/INC-001, INC-002, INC-003` | Investigated 3 structured incident scenarios; documented evidence chains, confidence levels, and recommended containment thresholds |
| Timeline reconstruction | `docs/network_forensics/network_forensics_workflow.md`, lab walkthroughs | Reconstructed multi-source event timelines correlating IDS alerts, DNS, flow records, and HTTP telemetry |
| Evidence preservation | `library/network_triage_checklist.md`, `LESSON_EXECUTION_COMPANION.md` | Practiced evidence-first investigation methodology; documented chain-of-custody and preservation procedures |

---

## Zero Trust & Policy Design

| Skill | Demonstrated In | CV Bullet |
|-------|----------------|-----------|
| Segmentation policy design | `labs/lab_04_zero_trust_segmentation_policy/` | Designed zero trust segmentation policy with explicit dependency mapping, logging requirements, and tested rollback procedures |
| Policy verification | `docs/zero_trust/segmentation_and_policy_verification.md` | Validated policy intent against real traffic patterns; identified dependency exceptions before deployment |
| Trust boundary analysis | `docs/foundations/network_security_fundamentals.md` | Mapped trust boundaries and attack paths across multi-segment network architectures |

---

## Research Methods & Experimental Rigor

| Skill | Demonstrated In | CV Bullet |
|-------|----------------|-----------|
| Hypothesis-driven investigation | `docs/research_methods/experimental_design_for_detection_labs.md` | Applied experimental design principles to detection tuning: pre-defined hypotheses, controlled variables, documented limitations |
| Metrics-based decision making | `LESSON_RESEARCH_ANALYSIS_COMPANION.md`, lab walkthroughs | Defined quantitative success metrics before implementing detection changes; documented results with explicit confidence levels |

---

## Professional Summary (CV-ready)

**Network Security Analyst:**
Hands-on experience with Suricata IDS, network protocol analysis, and detection engineering. Built Python tooling for automated EVE log triage. Investigated TLS anomalies, port scan incidents, and noisy rule scenarios with evidence-based methodology.

**Detection Engineer:**
Developed and tuned IDS detection rules using version-controlled configuration with automated regression testing. Applied engineering discipline (metrics, rollback criteria, CI validation) to detection content lifecycle.

**Network Forensics / IR Trainee:**
Practiced structured incident response across scan, rule-noise, and TLS anomaly scenarios. Applied 5-step forensics workflow with explicit confidence levels and evidence gap documentation.

**Security Engineer:**
Designed zero trust segmentation policies with dependency-aware exception handling, audit logging requirements, and tested rollback procedures. Applied experimental rigor to security architecture validation.
