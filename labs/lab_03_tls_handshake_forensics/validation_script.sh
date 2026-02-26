#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
grep -q 'TLS Certificate Anomaly' incidents/tickets/INC-003_tls_certificate_anomaly.md
grep -q 'handshake metadata' docs/crypto_and_tls/tls_operational_security.md
echo 'Lab 03 validation passed.'
