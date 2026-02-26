import io
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = REPO_ROOT / "scripts"
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

import analyze_suricata_eve_sample as triage  # noqa: E402


class TestSuricataTriage(unittest.TestCase):
    def test_summary_counts(self) -> None:
        path = REPO_ROOT / "datasets" / "suricata" / "eve_sample.jsonl"
        summary = triage.summarize_events(triage.iter_events(path))

        self.assertEqual(summary["total_events"], 5)
        self.assertEqual(summary["event_types"]["alert"], 2)
        self.assertEqual(summary["event_types"]["flow"], 1)
        self.assertEqual(summary["alert_severity_counts"][1], 1)
        self.assertEqual(summary["alert_severity_counts"][2], 1)
        self.assertTrue(summary["top_alert_signatures"])

    def test_main_prints_summary(self) -> None:
        path = REPO_ROOT / "datasets" / "suricata" / "eve_sample.jsonl"
        buf = io.StringIO()
        with redirect_stdout(buf):
            rc = triage.main(["analyze_suricata_eve_sample.py", str(path)])
        self.assertEqual(rc, 0)
        out = buf.getvalue()
        self.assertIn("Suricata EVE Triage Summary", out)
        self.assertIn("total_events=5", out)


if __name__ == "__main__":
    unittest.main()

