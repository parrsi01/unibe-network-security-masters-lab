#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
out="$(python3 scripts/analyze_suricata_eve_sample.py datasets/suricata/eve_sample.jsonl)"
printf '%s\n' "$out" | grep -q 'total_events=5'
printf '%s\n' "$out" | grep -q 'alert_severity_counts={1: 1, 2: 1}'
echo 'Lab 01 validation passed.'
