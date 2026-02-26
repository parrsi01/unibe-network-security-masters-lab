# Step-by-Step Guide

## Setup Commands (Exact)

```bash
cat docs/zero_trust/segmentation_and_policy_verification.md
cat incidents/tickets/INC-001_suspicious_scan.md
```

**Expected terminal output**

Markdown guidance on segmentation verification and a scan-related incident scenario.

## Execution Steps

1. Define trust boundaries and protected assets.
2. List required service dependencies and exceptions.
3. Specify allow/deny decisions and logging requirements.
4. Define a verification test plan and rollback plan.

## Intentional Misconfiguration Scenario (Required)

Block a required dependency in the policy design and describe the resulting outage symptom.

## Real-World Operational Failure Simulation (Required)

Assume emergency changes are applied without logging; explain how this breaks incident reconstruction.

## Debugging Walkthrough (Required)

If policy design is inconsistent, rebuild from asset -> identity -> service dependency -> control -> verification.
