#!/usr/bin/env bash
# Write the Yes Human pack workspace files into a pack checkout (overwrites them).
# Usage: scripts/apply_pack_template.sh <pack_dir>
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
TPL="${HERE}/templates/pack"
PACK="${1:?Usage: apply_pack_template.sh <pack_dir>}"
YAML="${PACK}/yeshuman.yaml"

[[ -f "${YAML}" ]] || { echo "No yeshuman.yaml in ${PACK}" >&2; exit 1; }
field() { sed -n "s/^$1:[[:space:]]*//p" "${YAML}" | head -1 | tr -d "\"' "; }
HANDLE="$(field handle)"; API_PORT="$(field api_port)"; LABS_PORT="$(field labs_port)"
[[ -n "${HANDLE}" && -n "${API_PORT}" && -n "${LABS_PORT}" ]] || { echo "yeshuman.yaml needs handle, api_port, labs_port" >&2; exit 1; }

mkdir -p "${PACK}/.cursor"
cp "${TPL}/AGENTS.md" "${PACK}/AGENTS.md"
cp "${TPL}/.cursor/install.sh" "${TPL}/.cursor/Dockerfile" "${PACK}/.cursor/"
chmod +x "${PACK}/.cursor/install.sh"
sed -e "s/__HANDLE__/${HANDLE}/g" -e "s/__API_PORT__/${API_PORT}/g" -e "s/__LABS_PORT__/${LABS_PORT}/g" \
  "${TPL}/.cursor/environment.json.tmpl" > "${PACK}/.cursor/environment.json"
while IFS= read -r line; do
  grep -qxF "${line}" "${PACK}/.gitignore" 2>/dev/null || echo "${line}" >> "${PACK}/.gitignore"
done < "${TPL}/.gitignore"

echo "Applied pack template to ${PACK} (${HANDLE}: labs ${LABS_PORT}, api ${API_PORT})"
