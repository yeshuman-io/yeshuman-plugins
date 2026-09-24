# Yes Human pack

This repo is a **tenant pack** for the Yes Human platform: this tenant's config, theme, seeds and plugins. The platform (Django API + Labs UI) is a separate repo, checked out **read-only** at `.platform/` by `.cursor/install.sh`.

## Before you start

This repo's default branch is the working base; do not look for another base branch.

Cursor Cloud secrets this workspace needs (set on the team or this environment):

- `YESHUMAN_PLATFORM_TOKEN` — read access to the platform repo (required)
- `OPENAI_API_KEY` — agent chat (required for `verify --check-openai`)
- `YESHUMAN_PLATFORM_REF` — platform branch or tag (optional, default `master`)

The Cursor "Set up environment" agent runs on Cursor's default image, not `.cursor/Dockerfile`, so Postgres 18 + pgvector and `uv` are missing there. Install them on the VM only to validate (the recipe is `.platform/.cursor/Dockerfile`), and keep the committed `.cursor/environment.json`; do not edit or replace it. Agents started normally on this repo build from the Dockerfile and already have the toolchain.

If `.platform/` is missing or install failed, check them with `for v in YESHUMAN_PLATFORM_TOKEN OPENAI_API_KEY YESHUMAN_PLATFORM_REF; do [ -n "${!v:-}" ] && echo "$v set" || echo "$v MISSING"; done` (never print values). If a required one is missing, stop and ask the user to add it in the Cursor dashboard, then start a new agent — secrets load when the VM boots. Do not work around a missing secret.

## When something breaks

If install, run or verify fails, or these instructions don't match what you find:

1. Do not edit `.cursor/*` (install script, environment, Dockerfile) or copy platform logic into this pack to get past it. These files are managed by Yes Human.
2. Open an issue on **this repo** labelled `agent-feedback`: the command you ran, the error (last lines of output), and which instruction was wrong or missing. Never paste secret values.
3. Stop and tell the user, with the issue link.

## Run it

- Install (Cursor Cloud does this on boot): `bash .cursor/install.sh`
- Start API + Labs: `bash .platform/scripts/pack_workspace/run.sh`
- Ports and handle are in `yeshuman.yaml`. Default login: `cloud@yeshuman.local` / `clouddev` unless `YESHUMAN_SEED_DEPLOYMENT_USERS` is set.
- Logs: `.platform/api/logs/<handle>.log`

## What lives where

- `yeshuman.yaml` — handle, ports, modules, seeds, flags.
- `config/api.json`, `config/ui.json` — tenant config (features, copy, theme, nav).
- `plugin/django/` — tenant-owned Django apps (`PLUGIN` in `__init__.py`).
- `plugin/labs/` — tenant-owned Labs routes, nav and components (`index.ts`).

## Pack or platform?

If the request can be met with config, theme, seeds or a pack plugin using the extension points the platform already offers, change **this repo** and open a PR here. If it needs a new extension point or a change to shared behaviour, it is a **platform** change: do not edit `.platform/`. Prototype it there if useful, then open an issue on this repo labelled `platform-request` with the problem, the proposed change and the diff (`git -C .platform diff`). Yes Human triages it.

Install the `yeshuman-pack` Cursor plugin (team marketplace) for the detailed skills.
