# Network Security Foundation Lab

![Python](https://img.shields.io/badge/Python-3.11%2B-3776AB?logo=python&logoColor=white)
[![CI](https://github.com/parrsi01/network-security-foundation-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/parrsi01/network-security-foundation-lab/actions/workflows/ci.yml)
[![Lint](https://github.com/parrsi01/network-security-foundation-lab/actions/workflows/lint.yml/badge.svg)](https://github.com/parrsi01/network-security-foundation-lab/actions/workflows/lint.yml)

Author: Simon Parris  
Date: 2026-02-26

Professional, structured network security training repository focused on junior-to-intermediate operational competence, reproducibility, and portfolio-quality documentation.

## Start Here

1. Open `01_START_HERE.md`
2. Read `docs/PROJECT_MANUAL.md`
3. Read `docs/LESSON_EXECUTION_COMPANION.md`
4. Run `./validate_repo.sh --quick`
5. Start with `labs/01_START_HERE.md`

## Scope

This repository combines:

- network security foundations and protocol threat analysis
- TLS/crypto operational security reasoning
- IDS/detection engineering (Suricata-style event triage workflows)
- network forensics and packet investigation practices
- zero trust / segmentation policy design
- incident ticket drills and evidence-first response
- structured analysis methods for investigations and tuning decisions

## Design Model

- `docs/` for structured theory and course manuals
- `Library/` for long-form reference notes
- `library/` for quick operational checklists and cheatsheets
- `labs/` for reproducible hands-on exercises
- `incidents/` for ticket-style triage and reporting drills
- `datasets/` for offline-safe sample telemetry
- `scripts/` for repeatable analysis tooling
- `tests/` for parser/triage utility verification
- `reports/` for generated artifacts and investigation summaries

## Quick Start

```bash
python3 -m venv venv
source venv/bin/activate
python -m pip install --upgrade pip
./validate_repo.sh --quick
python -m unittest discover -s tests -p 'test_*.py' -v
python scripts/analyze_suricata_eve_sample.py datasets/suricata/eve_sample.jsonl
```

## Learning Tracks

1. Foundations and protocol reasoning (`docs/foundations/`)
2. Protocol abuse and detection visibility (`docs/protocol_security/`)
3. TLS and crypto operations (`docs/crypto_and_tls/`)
4. Detection engineering and alert tuning (`docs/detection_engineering/`)
5. Network forensics (`docs/network_forensics/`)
6. Zero trust / segmentation (`docs/zero_trust/`)
7. Analysis methods and experiment discipline (`docs/research_methods/`)

## Standards

- Evidence-first troubleshooting and incident documentation
- Reproducible command sequences and validation steps
- Offline-readable notes (mobile/GitHub friendly)
- Version-controlled artifacts and portfolio-ready summaries
