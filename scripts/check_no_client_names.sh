#!/usr/bin/env bash
# Fail if this public repo mentions any client. Names come from the private fleet files, never from this repo.
# Usage: YESHUMAN_OPS_ROOT=../yeshuman-ops scripts/check_no_client_names.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
OPS="${YESHUMAN_OPS_ROOT:-${HERE}/../yeshuman-ops}"
[[ -d "${OPS}/fleet" ]] || { echo "Fleet files not found at ${OPS}/fleet (set YESHUMAN_OPS_ROOT)" >&2; exit 2; }

# Accounts, GitHub orgs, handles and pack repo names, excluding Yes Human's own.
NAMES="$(cat "${OPS}"/fleet/*.yaml \
  | sed -n -E 's/^(account|  org|  - handle|    pack_repo):[[:space:]]*//p' \
  | tr '/' '\n' | tr -d "\"' " | grep -v -E '^(null|yeshuman|yeshuman-io)$' | sort -u)"
[[ -n "${NAMES}" ]] || { echo "No client names parsed from fleet files" >&2; exit 2; }

PATTERN="$(echo "${NAMES}" | paste -sd'|')"
if git -C "${HERE}" grep -n -i -I -E "${PATTERN}" -- . ':!scripts/check_no_client_names.sh'; then
  echo "Client names found above. This repo is public." >&2
  exit 1
fi
echo "OK: no client names ($(echo "${NAMES}" | wc -l) checked)"
