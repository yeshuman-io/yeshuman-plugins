#!/usr/bin/env bash
# Fail if this public repo names a person from the fleet. Platform and plugin files name roles
# ("platform owner", "tenant owner"), never people. Names come from the private fleet files.
# Usage: YESHUMAN_OPS_ROOT=../yeshuman-ops scripts/check_no_people_names.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
OPS="${YESHUMAN_OPS_ROOT:-${HERE}/../yeshuman-ops}"
[[ -d "${OPS}/fleet" ]] || { echo "Fleet files not found at ${OPS}/fleet (set YESHUMAN_OPS_ROOT)" >&2; exit 2; }

# Cursor members, GitHub admins, contact and Slack identities; an email also contributes its local part.
NAMES="$(cat "${OPS}"/fleet/*.yaml \
  | sed -n -E 's/^[[:space:]]*(members|admins|contact_identity|identity):[[:space:]]*//p' \
  | tr -d "[]\"'" | tr ', ' '\n\n' \
  | sed -E 's/^([^@]+)@.*$/\1\n&/' \
  | grep -v -E '^(|null|yeshuman|yeshuman-io)$' | sort -u)"
[[ -n "${NAMES}" ]] || { echo "No people names parsed from fleet files" >&2; exit 2; }

PATTERN="$(echo "${NAMES}" | sed 's/[.[\*^$()+?{|]/\\&/g' | paste -sd'|')"
if git -C "${HERE}" grep -n -i -I -w -E "${PATTERN}" -- . ':!scripts/check_no_people_names.sh'; then
  echo "People's names found above. Name the role (platform owner, tenant owner) instead." >&2
  exit 1
fi
echo "OK: no people's names ($(echo "${NAMES}" | wc -l) checked)"
