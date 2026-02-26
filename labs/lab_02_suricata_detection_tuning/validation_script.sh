#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
grep -q 'triage_priority:' configs/triage_rules.yaml
grep -q 'severity_1: critical' configs/triage_rules.yaml
echo 'Lab 02 validation passed.'
