#!/usr/bin/env python3
"""Print a compact coverage summary for backend JaCoCo + Flutter LCOV reports."""
from __future__ import annotations

from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def pct(covered: int, missed: int) -> str:
    total = covered + missed
    return "n/a" if total == 0 else f"{covered / total * 100:.1f}% ({covered}/{total})"


def jacoco() -> str:
    path = ROOT / "api" / "target" / "site" / "jacoco" / "jacoco.xml"
    if not path.exists():
        return f"Backend JaCoCo: chưa có báo cáo ({path.relative_to(ROOT)})"
    root = ET.parse(path).getroot()
    counters = {c.attrib["type"]: (int(c.attrib["covered"]), int(c.attrib["missed"])) for c in root.findall("counter")}
    line = counters.get("LINE", (0, 0))
    branch = counters.get("BRANCH", (0, 0))
    instruction = counters.get("INSTRUCTION", (0, 0))
    return "\n".join([
        f"Backend line coverage       : {pct(*line)}",
        f"Backend branch coverage     : {pct(*branch)}",
        f"Backend instruction coverage: {pct(*instruction)}",
        "JaCoCo HTML                 : api/target/site/jacoco/index.html",
    ])


def lcov() -> str:
    path = ROOT / "frontend" / "coverage" / "lcov.info"
    if not path.exists():
        return f"Flutter LCOV: chưa có báo cáo ({path.relative_to(ROOT)})"
    found = hit = 0
    branch_found = branch_hit = 0
    for raw in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        if raw.startswith("LF:"):
            found += int(raw[3:])
        elif raw.startswith("LH:"):
            hit += int(raw[3:])
        elif raw.startswith("BRF:"):
            branch_found += int(raw[4:])
        elif raw.startswith("BRH:"):
            branch_hit += int(raw[4:])
    lines = "n/a" if found == 0 else f"{hit / found * 100:.1f}% ({hit}/{found})"
    branches = "n/a" if branch_found == 0 else f"{branch_hit / branch_found * 100:.1f}% ({branch_hit}/{branch_found})"
    return "\n".join([
        f"Flutter line coverage       : {lines}",
        f"Flutter branch coverage     : {branches}",
        "Flutter LCOV                : frontend/coverage/lcov.info",
    ])


if __name__ == "__main__":
    print("\n=== COVERAGE SUMMARY ===")
    print(jacoco())
    print(lcov())
