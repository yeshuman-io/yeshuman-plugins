#!/usr/bin/env python3
"""Upload evidence files to a Linear issue and post an evidence comment (Linear GraphQL API, stdlib only).

Usage:
  python3 linear_evidence.py --issue TC-123 --file shot.png --file api.log --comment comment.md
  python3 linear_evidence.py --issue TC-123 --file shot.png            # upload + attach only
  python3 linear_evidence.py --issue TC-123 --check                    # key and issue lookup only

The key comes from --key-env (a variable name, never a value). Default: LINEAR_API_KEY, then
<HANDLE>_LINEAR_API_KEY with HANDLE from ./yeshuman.yaml. The script never prints the key.

In the comment file, write {{file:<basename>}} where a file should appear; it is replaced with
the uploaded asset URL (images as ![](url), anything else as a link). Files not referenced are
appended under "Attachments".
"""

from __future__ import annotations

import argparse
import json
import mimetypes
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

API = "https://api.linear.app/graphql"


def die(msg: str, code: int = 1) -> None:
    print(f"linear_evidence: {msg}", file=sys.stderr)
    sys.exit(code)


def resolve_key(key_env: str | None) -> tuple[str, str]:
    names = [key_env] if key_env else ["LINEAR_API_KEY"]
    if not key_env:
        manifest = Path("yeshuman.yaml")
        if manifest.is_file():
            m = re.search(r"^handle:\s*['\"]?([A-Za-z0-9_-]+)", manifest.read_text(), re.M)
            if m:
                names.append(f"{m.group(1).upper().replace('-', '_')}_LINEAR_API_KEY")
    for name in names:
        if os.environ.get(name):
            return name, os.environ[name]
    die(f"no Linear key in {', '.join(names)} (set one as a Cursor Cloud secret)", 2)
    raise AssertionError


def gql(key: str, query: str, variables: dict) -> dict:
    req = urllib.request.Request(
        API,
        data=json.dumps({"query": query, "variables": variables}).encode(),
        headers={"Content-Type": "application/json", "Authorization": key},
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            body = json.load(resp)
    except urllib.error.HTTPError as e:
        if e.code == 401:
            die("Linear API HTTP 401: key rejected (expired, revoked or wrong workspace)", 3)
        try:
            body = json.load(e)
        except ValueError:
            die(f"Linear API HTTP {e.code} {e.reason}", 3)
    if body.get("errors"):
        msgs = "; ".join(err.get("message", "?") for err in body["errors"])
        hint = " (wrong identifier, or the key cannot see that team)" if "Entity not found" in msgs else ""
        die(f"Linear API error: {msgs}{hint}", 3)
    return body["data"]


def issue_id(key: str, ident: str) -> tuple[str, str]:
    data = gql(key, "query($id:String!){issue(id:$id){id identifier url}}", {"id": ident})
    if not data.get("issue"):
        die(f"issue {ident} not found with this key", 3)
    return data["issue"]["id"], data["issue"]["url"]


def upload(key: str, path: Path) -> str:
    ctype = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    size = path.stat().st_size
    data = gql(
        key,
        "mutation($ct:String!,$fn:String!,$sz:Int!){fileUpload(contentType:$ct,filename:$fn,size:$sz)"
        "{success uploadFile{uploadUrl assetUrl headers{key value}}}}",
        {"ct": ctype, "fn": path.name, "sz": size},
    )
    up = data["fileUpload"]["uploadFile"]
    headers = {"Content-Type": ctype, "Cache-Control": "public, max-age=31536000"}
    headers.update({h["key"]: h["value"] for h in up["headers"]})
    req = urllib.request.Request(up["uploadUrl"], data=path.read_bytes(), headers=headers, method="PUT")
    try:
        urllib.request.urlopen(req, timeout=300).close()
    except urllib.error.HTTPError as e:
        die(f"upload of {path.name} failed: HTTP {e.code}", 4)
    return up["assetUrl"]


def embed(name: str, url: str) -> str:
    ctype = mimetypes.guess_type(name)[0] or ""
    return f"![{name}]({url})" if ctype.startswith("image/") else f"[{name}]({url})"


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--issue", required=True, help="Issue identifier, e.g. TC-123")
    p.add_argument("--file", action="append", default=[], type=Path, help="Evidence file (repeatable)")
    p.add_argument("--comment", type=Path, help="Markdown comment body to post")
    p.add_argument("--key-env", help="Name of the env var holding the Linear key")
    p.add_argument("--no-attach", action="store_true", help="Do not also add files as issue attachments")
    p.add_argument("--check", action="store_true", help="Only check the key and the issue")
    a = p.parse_args()

    name, key = resolve_key(a.key_env)
    iid, url = issue_id(key, a.issue)
    print(f"key {name}: ok; issue {a.issue}: {url}")
    if a.check:
        return

    for f in a.file:
        if not f.is_file():
            die(f"no such file: {f}")
    if a.comment:
        names = {f.name for f in a.file}
        for ref in re.findall(r"\{\{file:([^}]+)\}\}", a.comment.read_text()):
            if ref.strip() not in names:
                die(f"comment references {{{{file:{ref.strip()}}}}} but no --file has that name")
    assets: dict[str, str] = {}
    for f in a.file:
        assets[f.name] = upload(key, f)
        print(f"uploaded {f.name}")
        if not a.no_attach:
            gql(
                key,
                "mutation($i:String!,$u:String!,$t:String!){attachmentCreate(input:{issueId:$i,url:$u,title:$t}){success}}",
                {"i": iid, "u": assets[f.name], "t": f.name},
            )

    if a.comment:
        body = a.comment.read_text()
        used = set()

        def sub(m: re.Match) -> str:
            fname = m.group(1).strip()
            used.add(fname)
            return embed(fname, assets[fname])

        body = re.sub(r"\{\{file:([^}]+)\}\}", sub, body)
        rest = [n for n in assets if n not in used]
        if rest:
            body += "\n\n**Attachments**\n\n" + "\n".join(f"- {embed(n, assets[n])}" for n in rest)
        data = gql(
            key,
            "mutation($i:String!,$b:String!){commentCreate(input:{issueId:$i,body:$b}){success comment{url}}}",
            {"i": iid, "b": body},
        )
        print(f"comment: {data['commentCreate']['comment']['url']}")


if __name__ == "__main__":
    main()
