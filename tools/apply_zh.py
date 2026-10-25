#!/usr/bin/env python3
"""Patch only complete quoted UI literals; leave URLs, keys and plugins alone."""
from __future__ import annotations
import hashlib
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
TR = json.loads((HERE / "zh_CN.json").read_text(encoding="utf-8"))
RUNTIME_IDENTIFIERS = {"GSM Settings", "Reminders"}
TOKEN = re.compile(r"""(?<![\w])(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')""")


def replace_literals(text: str, counts: dict[str, int]) -> str:
    def update(match: re.Match[str]) -> str:
        token = match.group(0)
        quote = token[0]
        original = token[1:-1]
        candidate = TR.get(original)
        if original in RUNTIME_IDENTIFIERS or candidate is None or quote in candidate or ("\\" in candidate and "\\" not in original):
            return token
        counts[original] = counts.get(original, 0) + 1
        return quote + candidate + quote

    return TOKEN.sub(update, text)


def main() -> int:
    files = [ROOT / "lib" / "main.dart", *sorted((ROOT / "lib" / "ui").rglob("*.dart"))]
    if not (ROOT / "pubspec.yaml").exists() or len(files) < 20:
        raise RuntimeError("Not a complete Hedon Haven checkout")
    counts: dict[str, int] = {}
    modified = 0
    for path in files:
        source = path.read_text(encoding="utf-8")
        translated = replace_literals(source, counts)
        if source != translated:
            path.write_text(translated, encoding="utf-8", newline="")
            modified += 1
    if len(counts) < 100:
        raise RuntimeError(f"Translation coverage unexpectedly low: {len(counts)} unique entries")
    report = {
        "dictionary_entries": len(TR),
        "unique_translations_applied": len(counts),
        "occurrences": sum(counts.values()),
        "files_modified": modified,
        "source": "Hedon-Haven/Hedon-Haven tag v0.6.7",
    }
    (HERE / "translation-report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
