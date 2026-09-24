#!/usr/bin/env bash
# Cursor Cloud install for a Yes Human pack: fetch the platform read-only into .platform/, then hand off.
set -euo pipefail

PACK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REF="${YESHUMAN_PLATFORM_REF:-master}"
: "${YESHUMAN_PLATFORM_TOKEN:?Set Cursor Cloud secret YESHUMAN_PLATFORM_TOKEN (read access to yeshuman-io/yeshuman)}"

rm -rf "${PACK_ROOT}/.platform"
git clone --depth 1 --branch "${REF}" \
  "https://x-access-token:${YESHUMAN_PLATFORM_TOKEN}@github.com/yeshuman-io/yeshuman.git" "${PACK_ROOT}/.platform"
git -C "${PACK_ROOT}/.platform" remote set-url origin https://github.com/yeshuman-io/yeshuman.git

PACK_ROOT="${PACK_ROOT}" exec bash "${PACK_ROOT}/.platform/scripts/pack_workspace/install.sh"
