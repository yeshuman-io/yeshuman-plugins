#!/usr/bin/env python3
"""Print findings a pack change adds: lines in HEAD's check output that BASE's output lacks.

Usage: new_findings.py <base_output> <head_output>

A finding is an indented line ("  path:12: message"). Line numbers are dropped before comparing,
so moving code is not a new finding. Counts matter: a second copy of the same finding is new.
Exit 1 when there is a new finding, 0 otherwise. Standard library only.
"""

from __future__ import annotations

import re
import sys
from collections import Counter
from pathlib import Path

_LINE_NO = re.compile(r":\d+(?=:)")


def findings(path: Path) -> Counter[str]:
    if not path.is_file():
        return Counter()
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    return Counter(_LINE_NO.sub("", line.strip()) for line in lines if line.startswith("  ") and line.strip())


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    base, head = findings(Path(argv[1])), findings(Path(argv[2]))
    new = head - base
    gone = base - head
    for line, count in sorted(new.items()):
        print(f"NEW  {line}" + (f" (x{count})" if count > 1 else ""))
    print(f"{sum(head.values())} on this branch, {sum(base.values())} on the base: {sum(new.values())} new, {sum(gone.values())} fixed.")
    return 1 if new else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
