#!/usr/bin/env python3
"""Turn pytest JUnit XML into a failure list, and compare a candidate run with a baseline run.

  pytest_failures.py collect <out.json> <junit.xml> [<rerun.xml>]
      failed = failed or errored in the first run and again in the rerun (when a rerun was made);
      flaky  = failed in the first run but passed in the rerun.
  pytest_failures.py compare <baseline.json> <candidate.json>
      new = candidate failures that the baseline did not have (failed or flaky there).
      Exit 1 when there is a new failure. Prints a Markdown summary for $GITHUB_STEP_SUMMARY.

Test ids are "path::name" from ``plugin/`` on, so ids match whichever checkout or platform ref ran them.
Standard library only.
"""

from __future__ import annotations

import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def test_id(case: ET.Element) -> str:
    classname = case.get("classname", "")
    name = case.get("name", "")
    path = case.get("file") or classname.replace(".", "/")
    index = path.find("plugin/")
    return f"{path[index:] if index >= 0 else path}::{name}" if path else name


def outcomes(junit: Path) -> tuple[set[str], set[str]]:
    """(failed, passed) test ids. A file that failed to collect counts as one failed id."""
    root = ET.parse(junit).getroot()
    failed: set[str] = set()
    passed: set[str] = set()
    for case in root.iter("testcase"):
        tid = test_id(case)
        if case.find("failure") is not None or case.find("error") is not None:
            failed.add(tid)
        elif case.find("skipped") is None:
            passed.add(tid)
    return failed, passed


def collect(out: Path, first: Path, rerun: Path | None) -> int:
    failed, passed = outcomes(first)
    flaky: set[str] = set()
    if rerun is not None and rerun.is_file():
        again, now_passing = outcomes(rerun)
        flaky = failed & now_passing
        failed -= flaky
    out.write_text(
        json.dumps({"failed": sorted(failed), "flaky": sorted(flaky), "passed": len(passed)}, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"{len(passed)} passed, {len(failed)} failed, {len(flaky)} flaky")
    return 0


def compare(baseline_path: Path, candidate_path: Path) -> int:
    baseline = json.loads(baseline_path.read_text(encoding="utf-8"))
    candidate = json.loads(candidate_path.read_text(encoding="utf-8"))
    known = set(baseline["failed"]) | set(baseline["flaky"])
    failed = set(candidate["failed"])
    new = sorted(failed - known)
    still = sorted(failed & known)
    fixed = sorted(set(baseline["failed"]) - failed - set(candidate["flaky"]))
    lines = [
        "### Pack suite: no new failures",
        "",
        f"Candidate: {candidate['passed']} passed, {len(failed)} failed, {len(candidate['flaky'])} flaky. "
        f"Baseline: {len(baseline['failed'])} failed.",
        "",
        f"**{'FAIL' if new else 'PASS'}**: {len(new)} new failure(s), {len(still)} already failing on the baseline, {len(fixed)} fixed.",
    ]
    for title, ids in (("New failures", new), ("Flaky (passed on rerun)", candidate["flaky"]), ("Fixed", fixed), ("Already failing", still)):
        if ids:
            lines += ["", f"<details{' open' if title == 'New failures' else ''}><summary>{title} ({len(ids)})</summary>", ""]
            lines += [f"- `{i}`" for i in ids]
            lines += ["", "</details>"]
    print("\n".join(lines))
    return 1 if new else 0


def main(argv: list[str]) -> int:
    if len(argv) >= 4 and argv[1] == "collect":
        return collect(Path(argv[2]), Path(argv[3]), Path(argv[4]) if len(argv) > 4 else None)
    if len(argv) == 4 and argv[1] == "compare":
        return compare(Path(argv[2]), Path(argv[3]))
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
