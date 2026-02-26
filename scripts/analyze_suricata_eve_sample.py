#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path
from typing import Iterable


def iter_events(path: Path) -> Iterable[dict]:
    for line_no, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        raw = raw.strip()
        if not raw:
            continue
        try:
            event = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise ValueError(f"Invalid JSONL at line {line_no}: {exc}") from exc
        if not isinstance(event, dict):
            raise ValueError(f"Line {line_no} is not a JSON object")
        yield event


def summarize_events(events: Iterable[dict]) -> dict:
    type_counter: Counter[str] = Counter()
    alert_severity_counter: Counter[int] = Counter()
    src_counter: Counter[str] = Counter()
    signatures: Counter[str] = Counter()
    total = 0

    for event in events:
        total += 1
        event_type = str(event.get("event_type", "unknown"))
        type_counter[event_type] += 1
        src_ip = str(event.get("src_ip", "unknown"))
        src_counter[src_ip] += 1

        if event_type == "alert":
            alert = event.get("alert", {})
            if isinstance(alert, dict):
                severity = alert.get("severity")
                if isinstance(severity, int):
                    alert_severity_counter[severity] += 1
                signature = alert.get("signature")
                if isinstance(signature, str):
                    signatures[signature] += 1

    return {
        "total_events": total,
        "event_types": dict(type_counter),
        "alert_severity_counts": dict(sorted(alert_severity_counter.items())),
        "top_source_ips": src_counter.most_common(5),
        "top_alert_signatures": signatures.most_common(5),
    }


def format_summary(summary: dict) -> str:
    lines = [
        "Suricata EVE Triage Summary",
        f"total_events={summary['total_events']}",
        f"event_types={summary['event_types']}",
        f"alert_severity_counts={summary['alert_severity_counts']}",
        f"top_source_ips={summary['top_source_ips']}",
        f"top_alert_signatures={summary['top_alert_signatures']}",
    ]
    return "\n".join(lines)


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("Usage: analyze_suricata_eve_sample.py <eve_jsonl_path>", file=sys.stderr)
        return 2
    path = Path(argv[1])
    if not path.exists():
        print(f"File not found: {path}", file=sys.stderr)
        return 1
    summary = summarize_events(iter_events(path))
    print(format_summary(summary))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

