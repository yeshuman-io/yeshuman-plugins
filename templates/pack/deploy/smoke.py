"""Smoke-check a deployed pack environment (Railway staging or a PR preview).

    uv run --with pyyaml deploy/smoke.py --api https://<handle>-api-staging.up.railway.app \
        [--labs https://<handle>-ui-staging.up.railway.app] [--record /api/public/opportunities]

Checks /api/health (healthy and bootstrapped), Labs 200, one seeds/demo.yaml login, and,
with --record, that a list endpoint returns at least one row. Prints codes only, never
passwords or tokens. Exits 1 if any check fails.
"""

from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

import yaml

PACK = Path(__file__).resolve().parent.parent


def request(url: str, body: dict | None = None) -> tuple[int, dict]:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read()
            status = resp.status
    except urllib.error.HTTPError as exc:
        raw, status = exc.read(), exc.code
    except urllib.error.URLError as exc:
        return 0, {"error": str(exc.reason)}
    try:
        return status, json.loads(raw or b"{}")
    except ValueError:
        return status, {}


def demo_user() -> dict | None:
    path = PACK / "seeds" / "demo.yaml"
    if not path.is_file():
        return None
    users = (yaml.safe_load(path.read_text()) or {}).get("users") or []
    return next((u for u in users if u.get("email") and u.get("password")), None)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--api", required=True)
    parser.add_argument("--labs")
    parser.add_argument("--record", help="API path that lists seeded rows, e.g. /api/public/opportunities")
    args = parser.parse_args()
    api = args.api.rstrip("/")
    failures = 0

    def report(name: str, ok: bool, detail: str) -> None:
        nonlocal failures
        failures += not ok
        print(f"{'ok  ' if ok else 'FAIL'} {name}: {detail}")

    status, health = request(f"{api}/api/health")
    report("health", status == 200 and health.get("status") == "healthy", f"{status}")
    if "bootstrapped" in health:
        report("bootstrapped", health["bootstrapped"] is True, str(health["bootstrapped"]))
    else:
        print("skip bootstrapped: platform does not report it yet")

    if args.labs:
        status, _ = request(args.labs.rstrip("/") + "/")
        report("labs", status == 200, f"{status}")

    user = demo_user()
    if user:
        status, body = request(
            f"{api}/api/accounts/login",
            {"username": user["email"], "password": str(user["password"])},
        )
        domain = str(user["email"]).split("@")[-1]
        report("demo login", status == 200, f"{status} (first seeds/demo.yaml user, @{domain})")
    else:
        print("skip demo login: no seeds/demo.yaml users")

    if args.record:
        status, body = request(f"{api}{args.record}")
        rows = body.get("total", len(body.get("results") or []))
        report("seeded record", status == 200 and bool(rows), f"{status}, {rows} row(s)")

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
