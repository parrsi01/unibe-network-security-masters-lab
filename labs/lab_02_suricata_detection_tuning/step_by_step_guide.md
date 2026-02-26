# Step-by-Step Guide

## Setup Commands (Exact)

```bash
python3 scripts/analyze_suricata_eve_sample.py datasets/suricata/eve_sample.jsonl
cat configs/triage_rules.yaml
```

**Expected terminal output**

A triage summary and a YAML policy showing severity mapping and analyst notes.

## Execution Steps

1. Review current alert mix from the sample telemetry.
2. Propose a tuning change for a noisy rule class.
3. Define metrics: alert rate, analyst review time, missed critical alerts.
4. Document rollback triggers.

## Intentional Misconfiguration Scenario (Required)

Treat severity 1 and severity 4 as the same priority and observe how triage focus degrades.

## Real-World Operational Failure Simulation (Required)

Simulate an over-tuned rule that removes useful alerts and explain how you would detect the loss.

## Debugging Walkthrough (Required)

If tuning logic is unclear, start from the detection objective and map each rule decision to a measurable analyst outcome.
