# Code Explanations — Scripts Walkthrough

---

## analyze_suricata_eve_sample.py

### Purpose
Parses Suricata's EVE JSON log format (one JSON object per line) and produces a structured triage summary. Designed to be run from the CLI and its output is machine-verifiable (used in CI via `validate_repo.sh`).

### Line-by-Line Walkthrough

```python
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path
```
- `json`: stdlib — parses JSON objects
- `sys`: provides `sys.argv` for CLI argument reading
- `Counter`: subclass of dict; counts hashable objects (perfect for protocol/severity tallies)
- `defaultdict`: dict that auto-creates missing keys with a factory (avoids `KeyError` on first access)
- `Path`: object-oriented path handling; cleaner than `os.path` string manipulation

---

```python
def iter_events(path: Path):
    with open(path, "r") as fh:
        for line in fh:
            line = line.strip()
            if line:
                yield json.loads(line)
```
**Why a generator?** `yield` makes this a generator — it reads one line at a time without loading the entire file into memory. For large EVE logs (GB-scale in production), this is critical. `if line:` skips blank lines which are valid in JSONL format.

**Why JSONL and not JSON?** A full JSON array `[{...}, {...}]` requires the entire file to be valid before any parsing begins. JSONL (one JSON object per line) allows incremental parsing and appending without rewriting the file — critical for logs that are written continuously.

**`json.loads()` vs `json.load()`**: `loads()` parses a string; `load()` reads from a file object. Since we're reading line by line from a file, we use `loads()` on each individual line string.

---

```python
def summarize_events(path: Path) -> dict:
    event_types = Counter()
    severities = Counter()
    src_ips = Counter()
    alert_signatures = []

    for event in iter_events(path):
        event_type = event.get("event_type", "unknown")
        event_types[event_type] += 1

        if event_type == "alert":
            sev = event.get("alert", {}).get("severity")
            if sev is not None:
                severities[sev] += 1
            sig = event.get("alert", {}).get("signature")
            if sig:
                alert_signatures.append(sig)

        src_ip = event.get("src_ip")
        if src_ip:
            src_ips[src_ip] += 1

    return {
        "total_events": sum(event_types.values()),
        "event_types": dict(event_types),
        "alert_severities": dict(severities),
        "top_src_ips": src_ips.most_common(5),
        "alert_signatures": alert_signatures,
    }
```

**`event.get("alert", {}).get("severity")`**: chained `.get()` with a default of `{}` for the outer get. If `"alert"` key is missing (non-alert events), `.get("alert", {})` returns an empty dict instead of raising `KeyError`. Then `.get("severity")` on the empty dict returns `None` safely.

**Why `Counter` not plain dict?** `Counter()["key"] += 1` works even if "key" was never set (Counter initializes missing keys to 0). With a plain `dict` you'd need `dict.setdefault("key", 0) += 1` or a `try/except`.

**`most_common(5)`**: built-in Counter method — returns top N elements by count as list of `(element, count)` tuples. O(n log k) via heapq — efficient even for large dictionaries.

**Why top-5 not all IPs?** Triage summaries should surface actionable signal. Listing 500 source IPs is noise; the top 5 cover the most active/interesting actors. Full data is in the JSONL if needed.

---

```python
def format_summary(summary: dict) -> str:
    lines = [
        "=== Suricata EVE Triage Summary ===",
        f"total_events={summary['total_events']}",
        ...
    ]
    return "\n".join(lines)
```

**Why `total_events=5` format (not human prose)?** The validation script uses `grep "total_events=5"` to assert the output. Machine-readable key=value format allows both human reading and automated assertion in bash. This is the "labeled output" pattern — every critical metric gets a parseable label.

---

```python
def main():
    if len(sys.argv) != 2:
        print("Usage: analyze_suricata_eve_sample.py <path>", file=sys.stderr)
        sys.exit(1)
    path = Path(sys.argv[1])
    summary = summarize_events(path)
    print(format_summary(summary))
```

**Why `sys.stderr` for usage error?** Error messages go to stderr so they don't pollute stdout output which may be piped into other tools. The main output goes to stdout.

**Why `sys.exit(1)`?** Exit code 1 signals failure to the calling shell. Validation scripts check exit codes — `sys.exit(1)` causes `bash -e` pipelines to abort.

**Why a single path argument?** Simple, composable CLI design. The script does one thing: analyze a path. Callers can loop over multiple files in shell.

---

## validate_repo.sh

### Key Patterns

**`bash -n <script>`** — Syntax-only check. Bash parses the script without executing it. Catches syntax errors (unclosed strings, missing `fi`/`done`) without running potentially destructive commands. This is why it's safe to run in CI.

**`--quick` flag pattern:**
```bash
QUICK=false
for arg in "$@"; do
    [[ "$arg" == "--quick" ]] && QUICK=true
done
```
Allows `make validate-quick` to skip slow checks (unit tests, full Python validation) for rapid CI feedback in pre-commit hooks while `make validate` runs the full suite.

**Exit code conventions:**
- `exit 0` = success (all validations passed)
- `exit 1` = failure (missing file, failing test, placeholder found)
- Scripts should `set -e` or explicitly check return codes — failures should propagate

**The `total_events=5` assertion:**
```bash
OUTPUT=$(python3 scripts/analyze_suricata_eve_sample.py datasets/suricata/eve_sample.jsonl)
echo "$OUTPUT" | grep -q "total_events=5" || { echo "FAIL: expected total_events=5"; exit 1; }
```
This is a **regression test in bash**. It validates that the script still produces the correct output for the known dataset. If someone changes the JSONL or the script, this assertion catches the break. This is the same principle as unit tests but implemented in shell for CI portability (no Python test runner needed just for this check).

---

## test_suricata_triage.py

### Structure

```python
import unittest
from pathlib import Path
import subprocess
import sys
```

**`unittest.TestCase`** — Python's built-in test framework. Methods starting with `test_` are discovered and run automatically. `self.assert*` methods raise `AssertionError` on failure, which unittest catches and reports.

### test_summary_counts

```python
def test_summary_counts(self):
    path = Path("datasets/suricata/eve_sample.jsonl")
    summary = summarize_events(path)
    self.assertEqual(summary["total_events"], 5)
    self.assertEqual(summary["event_types"]["alert"], 2)
```
**Unit test**: directly calls Python functions. Tests the logic in isolation. Fast, no subprocess overhead. If `summarize_events()` has a bug, this catches it without invoking the CLI layer.

### test_main_prints_summary

```python
def test_main_prints_summary(self):
    result = subprocess.run(
        [sys.executable, "scripts/analyze_suricata_eve_sample.py",
         "datasets/suricata/eve_sample.jsonl"],
        capture_output=True, text=True
    )
    self.assertEqual(result.returncode, 0)
    self.assertIn("total_events=5", result.stdout)
```
**Integration test (CLI test)**: runs the script as a subprocess, just like a user would. Tests the full stack: `main()` → argparse → `summarize_events()` → `format_summary()` → stdout. This catches issues that unit tests miss: wrong argument parsing, wrong output format, unexpected exceptions in `main()`.

**Why both unit AND integration tests?** Unit tests catch logic bugs; integration tests catch interface bugs. A correctly implemented `summarize_events()` could still produce wrong output if `format_summary()` or `main()` has a bug. The two test types are complementary, not redundant.

**`sys.executable`**: uses the same Python interpreter running the test rather than hardcoding `python3`. Important when testing in virtual environments.

### Lab Validation Scripts (grep pattern)

```bash
# lab_02_suricata_detection_tuning/validation_script.sh
grep -q "triage_priority:" configs/triage_rules.yaml || exit 1
grep -q "severity_1: critical" configs/triage_rules.yaml || exit 1
echo "Lab 02 validation passed."
```

**Why grep-based validation?** These lab validations check that the student has the required content in configuration files — they're testing _presence_ of specific strings, not Python logic. Grep is the right tool: fast, no Python required, easy to read.

**`grep -q`**: quiet mode — exits with code 0 if found, 1 if not found, without printing. Perfect for conditional checks.

**`|| exit 1`**: if grep returns non-zero (string not found), immediately exit with failure. This is the bash `or` idiom for early-exit on failure.

**Pattern across all 4 labs:**
- Lab 01: validates Python script output format
- Lab 02: validates config file content
- Lab 03: validates that required documentation strings exist in the incident ticket and theory doc
- Lab 04: validates that zero trust concept text exists in the policy verification doc

This validates *learning artifacts* — checking that the student engaged with the material by verifying specific phrases are present in the expected documents.
