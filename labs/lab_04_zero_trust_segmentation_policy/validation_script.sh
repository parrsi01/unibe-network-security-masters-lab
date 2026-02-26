#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
grep -q 'Zero trust designs fail' docs/zero_trust/segmentation_and_policy_verification.md
grep -q 'Suspicious Scan' incidents/tickets/INC-001_suspicious_scan.md
echo 'Lab 04 validation passed.'
