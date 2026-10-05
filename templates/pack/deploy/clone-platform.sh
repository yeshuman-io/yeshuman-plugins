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
rm -rf "${dest}/.git"
[ -n "${keyfile}" ] && rm -f "${keyfile}"
exit 0
