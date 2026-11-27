#!/usr/bin/env python3
"""Run one platform check on a pack's PR branch and its base; fail only on findings the PR adds.

Usage: run_diff_check.py <check> <platform_dir> <pack_dir> [<base_dir>]
  check: sdk-imports | terminology
Without a base checkout (a push, or a base that predates the pack layout) any finding fails.
Writes a short result to $GITHUB_STEP_SUMMARY when it is set. Standard library only.
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from new_findings import findings  # noqa: E402


def command(check: str, platform: Path, pack: Path) -> list[str]:
    if check == "sdk-imports":
        return [sys.executable, str(platform / "scripts" / "check_pack_sdk_imports.py"), str(pack)]
    if check == "terminology":
        return [sys.executable, str(platform / "scripts" / "check_terminology.py"), "--root", str(pack)]
    raise SystemExit(f"unknown check {check}")


def run(check: str, platform: Path, pack: Path, out: Path) -> int:
    proc = subprocess.run(command(check, platform, pack), capture_output=True, text=True, check=False)
    out.write_text(proc.stdout + proc.stderr, encoding="utf-8")
    return proc.returncode


def summary(text: str) -> None:
    path = os.environ.get("GITHUB_STEP_SUMMARY")
    if path:
        with open(path, "a", encoding="utf-8") as fh:
            fh.write(text + "\n")


def main(argv: list[str]) -> int:
    if len(argv) not in (4, 5):
        print(__doc__, file=sys.stderr)
        return 2
    check, platform, pack = argv[1], Path(argv[2]), Path(argv[3])
    base = Path(argv[4]) if len(argv) == 5 else None
    tmp = Path(os.environ.get("RUNNER_TEMP", "/tmp"))
    head_out, base_out = tmp / f"{check}-head.txt", tmp / f"{check}-base.txt"
    head_code = run(check, platform, pack, head_out)
    print(head_out.read_text(encoding="utf-8"))
    if head_code == 0:
        summary(f"- **{check}**: PASS")
        return 0
    if base is None or not (base / "yeshuman.yaml").is_file():
        summary(f"- **{check}**: FAIL (no base branch to compare with)")
        return 1
    run(check, platform, base, base_out)
    head, old = findings(head_out), findings(base_out)
    new = head - old
    if not head:
        # The check failed without listing findings (a crash or a usage error): fail loudly.
        summary(f"- **{check}**: FAIL (check did not run cleanly)")
        return 1
    print(f"--- compared with the base branch: {sum(new.values())} new, {sum((old - head).values())} fixed")
    for line in sorted(new):
        print(f"::error title={check}::{line}")
    verdict = "FAIL" if new else "PASS"
    summary(f"- **{check}**: {verdict}: {sum(new.values())} new, {sum(head.values())} on this branch, {sum(old.values())} on the base")
    return 1 if new else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
