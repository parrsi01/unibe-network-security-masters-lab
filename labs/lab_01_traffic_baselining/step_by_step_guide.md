# Step-by-Step Guide

## Setup Commands (Exact)

```bash
python3 scripts/analyze_suricata_eve_sample.py datasets/suricata/eve_sample.jsonl
```

**Expected terminal output**

A summary with `total_events=5`, event type counts, alert severities, and top source IPs.

## Execution Steps

1. Run the triage script on the sample EVE file.
2. Identify which events are baseline activity and which are alerts.
3. Write a short analyst summary with evidence.

## Intentional Misconfiguration Scenario (Required)

Edit a copy of the sample and change one `event_type` to an unexpected value; observe how the summary groups it.

## Real-World Operational Failure Simulation (Required)

Assume an analyst treats all alerts as equal severity and misses prioritization. Compare outcomes with severity-based ordering.

## Debugging Walkthrough (Required)

If counts look wrong, validate JSONL formatting first, then inspect `event_type` values and alert severity types.
