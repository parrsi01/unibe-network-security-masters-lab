#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

quick_mode=0
for arg in "$@"; do
  case "$arg" in
    --quick) quick_mode=1 ;;
    -h|--help)
      cat <<'USAGE'
Usage: ./validate_repo.sh [--quick]

Validates repo structure, docs/labs baselines, syntax checks, sample triage script, and unit tests.
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

failures=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures+1)); }
warn() { echo "WARN: $1"; }

check_file() { [[ -f "$1" ]] && pass "$1 present" || fail "$1 present"; }
check_dir() { [[ -d "$1" ]] && pass "$1 present" || fail "$1 present"; }

echo "Repository Validation"
check_file README.md
check_file 01_START_HERE.md
check_file 02_RUN_FIRST_ON_PHONE.md
check_file LICENSE
check_file Makefile
check_file pyproject.toml
check_file requirements.in
check_file requirements.txt
check_file validate_repo.sh
check_file scripts/analyze_suricata_eve_sample.py
check_file datasets/suricata/eve_sample.jsonl
check_file tests/test_suricata_triage.py

check_dir .github/workflows
check_file .github/workflows/ci.yml
check_file .github/workflows/lint.yml

check_dir docs
check_file docs/README.md
check_file docs/PROJECT_MANUAL.md
check_file docs/CORE_CONCEPTS.md
check_file docs/OFFLINE_INDEX.md
check_file docs/LESSON_EXECUTION_COMPANION.md
check_file docs/LESSON_RESEARCH_ANALYSIS_COMPANION.md
check_file docs/REPOSITORY_STATUS_REPORT.md
check_file docs/CV_READY_SUMMARY.md
check_file docs/PORTFOLIO_SKILL_MAPPING.md

check_dir Library
check_dir library
check_dir labs
check_dir incidents
check_dir configs
check_dir datasets
check_dir reports
check_dir scripts
check_dir tests

if python3 - <<'PY'
from pathlib import Path
import sys

labs = sorted([p for p in Path("labs").glob("lab_*") if p.is_dir()])
if len(labs) < 4:
    print(f"Expected at least 4 labs, found {len(labs)}")
    sys.exit(1)
required = [
    "README.md",
    "lab_objective.md",
    "step_by_step_guide.md",
    "full_solution.md",
    "common_errors.md",
    "troubleshooting_tree.md",
    "validation_script.sh",
]
for lab in labs:
    for name in required:
        p = lab / name
        if not p.exists():
            print(f"Missing {p}")
            sys.exit(1)
print(f"Validated {len(labs)} labs with standard documentation/validation files")
PY
then
  pass "Lab standards"
else
  fail "Lab standards"
fi

if python3 - <<'PY'
from pathlib import Path
import sys

library_files = sorted(Path("Library").glob("*.md"))
if len(library_files) < 8:
    print(f"Expected >=8 markdown files in Library, found {len(library_files)}")
    sys.exit(1)
print(f"Library count OK: {len(library_files)}")
PY
then
  pass "Library completeness"
else
  fail "Library completeness"
fi

if command -v rg >/dev/null 2>&1; then
  if rg -n "TODO|TBD|FIXME|PLACEHOLDER|REPLACE_WITH_|lorem ipsum" . \
    --glob '!**/.git/**' \
    --glob '!**/venv/**' \
    --glob '!**/.venv/**' \
    --glob '!validate_repo.sh' \
    --glob '!Makefile' \
    --glob '!.github/workflows/**' >/tmp/network_repo_placeholders.out; then
    cat /tmp/network_repo_placeholders.out
    fail "No placeholder/template markers remain"
  else
    pass "No placeholder/template markers remain"
  fi
else
  warn "Placeholder scan skipped (rg not installed)"
fi
rm -f /tmp/network_repo_placeholders.out

shell_failed=0
while IFS= read -r -d '' f; do
  if ! bash -n "$f"; then
    echo "Syntax error: $f"
    shell_failed=1
  fi
done < <(find scripts labs -type f -name '*.sh' -print0 2>/dev/null)
bash -n validate_repo.sh || shell_failed=1
[[ $shell_failed -eq 0 ]] && pass "Shell syntax checks" || fail "Shell syntax checks"

py_failed=0
pycache_tmp=""
cleanup_pycache_tmp() {
  if [[ -n "${pycache_tmp:-}" && -d "${pycache_tmp:-}" ]]; then
    rm -rf "$pycache_tmp"
  fi
}
trap cleanup_pycache_tmp EXIT
while IFS= read -r -d '' pyf; do
  pycache_tmp="$(mktemp -d)"
  if ! PYTHONPYCACHEPREFIX="$pycache_tmp" python3 -m py_compile "$pyf" >/dev/null 2>&1; then
    echo "Python syntax error: $pyf"
    py_failed=1
  fi
  rm -rf "$pycache_tmp"
  pycache_tmp=""
done < <(find scripts tests -type f -name '*.py' -print0 2>/dev/null)
[[ $py_failed -eq 0 ]] && pass "Python syntax checks" || fail "Python syntax checks"

if python3 scripts/analyze_suricata_eve_sample.py datasets/suricata/eve_sample.jsonl >/tmp/network_triage_sample.out 2>&1; then
  if rg -q "total_events=5" /tmp/network_triage_sample.out; then
    pass "Sample triage script run"
  else
    cat /tmp/network_triage_sample.out
    fail "Sample triage script run"
  fi
else
  cat /tmp/network_triage_sample.out
  fail "Sample triage script run"
fi
rm -f /tmp/network_triage_sample.out

if python3 -m unittest discover -s tests -p 'test_*.py' -v >/tmp/network_repo_unittest.out 2>&1; then
  pass "Unit tests"
else
  cat /tmp/network_repo_unittest.out
  fail "Unit tests"
fi
rm -f /tmp/network_repo_unittest.out

if [[ $quick_mode -eq 0 ]]; then
  echo
  echo "Repository Metrics"
  python3 - <<'PY'
from pathlib import Path
repo = Path(".")
print(f"docs_md={sum(1 for _ in (repo/'docs').rglob('*.md'))}")
print(f"library_md={sum(1 for _ in (repo/'Library').glob('*.md'))}")
print(f"labs={sum(1 for p in (repo/'labs').glob('lab_*') if p.is_dir())}")
print(f"incidents={sum(1 for _ in (repo/'incidents'/'tickets').glob('*.md'))}")
print(f"tests={sum(1 for _ in (repo/'tests').glob('test_*.py'))}")
PY
fi

if [[ $failures -ne 0 ]]; then
  echo "Validation failed with $failures issue(s)." >&2
  exit 1
fi

echo "Validation passed."

