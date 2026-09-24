# Yes Human pack

This repo is a **tenant pack** for the Yes Human platform: this tenant's config, theme, seeds and plugins. The platform (Django API + Labs UI) is a separate repo, checked out **read-only** at `.platform/` by `.cursor/install.sh`.

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
