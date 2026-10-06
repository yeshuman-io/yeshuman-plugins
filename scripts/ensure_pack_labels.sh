#!/usr/bin/env bash
# Create or update the pack's issue labels from templates/pack/.github/labels.tsv.
# Usage: scripts/ensure_pack_labels.sh <owner/repo>
# Needs a gh login (or GH_TOKEN) with Issues: write on the repo; a Cursor GitHub App token is not enough.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
REPO="${1:?Usage: ensure_pack_labels.sh <owner/repo>}"
status=0
while IFS=$'\t' read -r name color description; do
  [[ -n "${name}" ]] || continue
  if gh label create "${name}" --repo "${REPO}" --color "${color}" --description "${description}" --force >/dev/null 2>&1; then
    echo "label ${name}: ok on ${REPO}"
  else
    echo "label ${name}: could not create on ${REPO} (token needs Issues: write)" >&2
    status=1
  fi
done < "${HERE}/templates/pack/.github/labels.tsv"
exit "${status}"
