---
name: yh-pack-orientation
description: Orient in a Yes Human tenant pack — what the pack is, how the read-only platform in .platform/ relates to it, how to install and run the stack, and how to decide whether a request is a pack change or a platform change. Use at the start of any task in a repo that has yeshuman.yaml at its root.
---

# Yes Human pack orientation

## Two layers

| Layer | Where | Who changes it |
|-------|-------|----------------|
| **Pack** (this repo) | `yeshuman.yaml`, `config/`, `plugin/` | You, via PRs on this repo |
| **Platform** | `.platform/` (clone of the Yes Human platform, replaced on every install) | Yes Human only |

The platform is one codebase serving many tenants. It loads exactly one pack at runtime (`TENANT_ROOT` points at this repo) and reads the pack's config and plugins through fixed extension points. Nothing tenant-specific belongs in the platform.

## Install and run

1. `bash .cursor/install.sh` — clones the platform at `YESHUMAN_PLATFORM_REF` (default `master`) into `.platform/` using `YESHUMAN_PLATFORM_TOKEN`, then installs dependencies, the database and seeds for this pack's handle. Cursor Cloud runs this on boot.
2. `bash .platform/scripts/pack_workspace/run.sh` — starts API and Labs. Ports are `api_port` / `labs_port` in `yeshuman.yaml`.
3. Check: `cd .platform/cli && uv run yeshuman verify <handle>`. Logs: `.platform/api/logs/<handle>.log`.

Default login is `cloud@yeshuman.local` / `clouddev` unless `YESHUMAN_SEED_DEPLOYMENT_USERS` is set.

If install fails on the clone step, the Cloud secret `YESHUMAN_PLATFORM_TOKEN` is missing or cannot read the platform repo — report that; do not work around it.

## Pack or platform?

Ask: can this be done with what the platform already exposes?

- **Pack change** — copy, theme, nav, feature flags, landing (`config/ui.json`); tool catalog, features, integrations settings (`config/api.json`); modules, seeds, compositions (`yeshuman.yaml`); tenant-owned Django apps and Labs pages through the plugin slots (`plugin/`). Build it here, run it, open a PR on this repo. Use `yh-pack-feature`.
- **Platform change** — needs a new extension point, a new config key the platform does not read, a change to shared behaviour, a shared model or API, or a bug in platform code. Do not edit `.platform/` for real. Use `yh-platform-request`.
- **Both** — build the pack part now; raise a platform request for the missing piece and say in the pack PR what it waits on.

When unsure, grep `.platform/` for the config key or slot you need. If the platform does not read it, it is a platform change.
