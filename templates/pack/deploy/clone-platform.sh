#!/bin/sh
# Railway build: clone the Yes Human platform at YESHUMAN_PLATFORM_REF into <dest>.
# Credentials (build variables): YESHUMAN_PLATFORM_SSH_KEY (read-only deploy key PEM) or YESHUMAN_PLATFORM_TOKEN.
set -eu

dest="${1:?Usage: clone-platform.sh <dest>}"
repo="${YESHUMAN_PLATFORM_REPO:-yeshuman-io/yeshuman}"
ref="${YESHUMAN_PLATFORM_REF:-master}"
keyfile=""

if [ -n "${YESHUMAN_PLATFORM_SSH_KEY:-}" ]; then
  keyfile="$(mktemp)"
  printf '%s\n' "${YESHUMAN_PLATFORM_SSH_KEY}" | sed 's/\r$//' > "${keyfile}"
  if ! grep -q "BEGIN " "${keyfile}"; then
    printf '%s\n' "${YESHUMAN_PLATFORM_SSH_KEY}" | sed 's/\\n/\n/g' > "${keyfile}"
  fi
  chmod 600 "${keyfile}"
  export GIT_SSH_COMMAND="ssh -i ${keyfile} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
  url="git@github.com:${repo}.git"
elif [ -n "${YESHUMAN_PLATFORM_TOKEN:-}" ]; then
  url="https://x-access-token:${YESHUMAN_PLATFORM_TOKEN}@github.com/${repo}.git"
else
  echo "Set YESHUMAN_PLATFORM_SSH_KEY or YESHUMAN_PLATFORM_TOKEN as a Railway build variable (read access to ${repo})." >&2
  exit 1
fi

echo "==> clone ${repo}@${ref} -> ${dest}"
git clone --depth 1 --branch "${ref}" "${url}" "${dest}"
git -C "${dest}" log -1 --format='==> platform %h %s'

# Public SHAs only, written before .git is removed. /api/health reads this file.
# A non-hex value (a token, a branch name) is stored as JSON null.
json_sha() {
  case "$1" in
    ''|*[!0-9a-fA-F]*) printf 'null' ;;
    *) printf '"%s"' "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" ;;
  esac
}
platform_sha="$(git -C "${dest}" rev-parse HEAD)"
mkdir -p "${dest}/api/yeshuman"
printf '{"platform_commit":%s,"pack_commit":%s}\n' \
  "$(json_sha "${platform_sha}")" "$(json_sha "${RAILWAY_GIT_COMMIT_SHA:-}")" \
  > "${dest}/api/yeshuman/build-revision.json"

rm -rf "${dest}/.git"
[ -n "${keyfile}" ] && rm -f "${keyfile}"
exit 0
