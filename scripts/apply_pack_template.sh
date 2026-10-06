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
ORIGIN_URL="$(field origin_url)"
ORIGIN_WORKFLOW=""
if [[ -n "${ORIGIN_URL}" ]]; then
  [[ "${ORIGIN_URL}" =~ ^https://[A-Za-z0-9._/-]+$ ]] || { echo "yeshuman.yaml origin_url must be a plain https:// URL" >&2; exit 1; }
  ORIGIN_WORKFLOW=" Use the Origin workflow for this repo: open and review pull requests on Origin at ${ORIGIN_URL}."
fi

mkdir -p "${PACK}/.cursor"
sed -e "s|__ORIGIN_WORKFLOW__|${ORIGIN_WORKFLOW}|" "${TPL}/AGENTS.md" > "${PACK}/AGENTS.md"
cp "${TPL}/.cursor/install.sh" "${TPL}/.cursor/Dockerfile" "${PACK}/.cursor/"
chmod +x "${PACK}/.cursor/install.sh"
# Interim until team marketplace Cloud attach works: Cloud Agents load
# project skills/rules from the pack clone (.cursor/skills, .cursor/rules).
# Do not clone the plugin in install.sh / Dockerfile / environment.json.
if [[ -d "${TPL}/.cursor/skills" ]]; then
  mkdir -p "${PACK}/.cursor/skills"
  cp -R "${TPL}/.cursor/skills/." "${PACK}/.cursor/skills/"
fi
if [[ -d "${TPL}/.cursor/rules" ]]; then
  mkdir -p "${PACK}/.cursor/rules"
  cp -R "${TPL}/.cursor/rules/." "${PACK}/.cursor/rules/"
fi
mkdir -p "${PACK}/deploy"
cp "${TPL}/deploy/"* "${PACK}/deploy/"
cp "${TPL}/.dockerignore" "${PACK}/.dockerignore"
sed -e "s/__HANDLE__/${HANDLE}/g" -e "s/__API_PORT__/${API_PORT}/g" -e "s/__LABS_PORT__/${LABS_PORT}/g" \
  "${TPL}/.cursor/environment.json.tmpl" > "${PACK}/.cursor/environment.json"
if [[ -d "${PACK}/jobs" ]]; then
  sed -i "s/\(\"API\", \"port\": ${API_PORT} }\)/\1,\n    { \"name\": \"Jobs\", \"port\": 3008 }/" "${PACK}/.cursor/environment.json"
fi
while IFS= read -r line; do
  grep -qxF "${line}" "${PACK}/.gitignore" 2>/dev/null || echo "${line}" >> "${PACK}/.gitignore"
done < "${TPL}/.gitignore"

echo "Applied pack template to ${PACK} (${HANDLE}: labs ${LABS_PORT}, api ${API_PORT})"
