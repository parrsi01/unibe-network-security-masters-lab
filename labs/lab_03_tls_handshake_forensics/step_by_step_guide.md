# Step-by-Step Guide

## Setup Commands (Exact)

```bash
cat incidents/tickets/INC-003_tls_certificate_anomaly.md
cat docs/crypto_and_tls/tls_operational_security.md
```

**Expected terminal output**

Readable markdown content describing the TLS anomaly scenario and operational TLS analysis considerations.

## Execution Steps

1. List benign and malicious explanations for the anomaly.
2. Define the minimum evidence required before containment.
3. Describe a verification sequence (certificate chain, hostname, trust store, endpoint context).

## Intentional Misconfiguration Scenario (Required)

Assume hostname mismatch alone always means compromise; identify cases where this is false.

## Real-World Operational Failure Simulation (Required)

Simulate an urgent containment action with insufficient evidence and describe the service-impact risk.

## Debugging Walkthrough (Required)

If you cannot decide next steps, separate certificate validation issues from endpoint identity and routing/DNS context.
