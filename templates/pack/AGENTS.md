# Yes Human pack

This repo is a **tenant pack** for the Yes Human platform: this tenant's config, theme, seeds and plugins. The platform (Django API + Labs UI) is a separate repo, checked out **read-only** at `.platform/` by `.cursor/install.sh`.

## Before you start

This repo's default branch is the working base; do not look for another base branch. While it is `staging`, that is pre-production: Railway staging and Cursor Cloud build from it, and `master` is production, promoted from `staging` by Yes Human. Open PRs against `staging`. You may merge your own PR to `staging` when it meets the high-confidence bar in `yeshuman-pack-feature` (Merge); otherwise leave it open for Yes Human. Squash merges only (`gh pr merge --squash` or API `merge_method=squash`), never a merge commit or a rebase. Never merge or push to `master`; Yes Human promotes.__ORIGIN_WORKFLOW__

Cursor Cloud secrets this workspace needs (set on the team or this environment):

- `YESHUMAN_PLATFORM_TOKEN` — read access to the platform repo (required)
- `OPENAI_API_KEY` — agent chat (required for `verify --check-openai`)
- `YESHUMAN_PLATFORM_REF` — platform branch or tag (default `master`; set it to `staging` while this repo's default branch is `staging`)

The Cursor "Set up environment" agent runs on Cursor's default image, not `.cursor/Dockerfile`, so Postgres 18 + pgvector and `uv` are missing there. Install them on the VM only to validate (the recipe is `.platform/.cursor/Dockerfile`), and keep the committed `.cursor/environment.json`; do not edit or replace it. Agents started normally on this repo build from the Dockerfile and already have the toolchain.

If `.platform/` is missing or install failed, check them with `for v in YESHUMAN_PLATFORM_TOKEN OPENAI_API_KEY YESHUMAN_PLATFORM_REF; do [ -n "${!v:-}" ] && echo "$v set" || echo "$v MISSING"; done` (never print values). If a required one is missing, stop and ask the user to add it in the Cursor dashboard, then start a new agent — secrets load when the VM boots. Do not work around a missing secret.

## When something breaks

If install, run or verify fails, or these instructions don't match what you find:

1. Do not edit `.cursor/*` (install script, environment, Dockerfile) or copy platform logic into this pack to get past it. These files are managed by Yes Human.
2. Open an issue on **this repo** labelled `agent-feedback`: the command you ran, the error (last lines of output), and which instruction was wrong or missing. Never paste secret values.
3. If issue creation fails (the Cloud token may lack Issues permission), put the same text under `## Agent feedback` in your PR body, or in your reply if you have no PR.
4. Stop and tell the user, with the issue or PR link.

## Evidence on Linear

If your work is tied to a Linear issue, post evidence on that issue and put the same Given/When/Then "How to verify" block in the PR body. Evidence means a screenshot or short video for UI changes, and a request/response or test output for backend changes. Follow `yeshuman-linear-evidence`. If you cannot capture or post evidence, say so explicitly; never fake it. User-visible changes need evidence before you self-merge to `staging`. If Linear is unreachable, the full evidence in the PR body counts; say that Linear posting failed and post to the issue once access works.

## Run it

- Install (Cursor Cloud does this on boot): `bash .cursor/install.sh`
- Start API + Labs: `bash .platform/scripts/pack_workspace/run.sh`
- Ports and handle are in `yeshuman.yaml`. Default login: `cloud@yeshuman.local` / `clouddev` unless `YESHUMAN_SEED_DEPLOYMENT_USERS` is set.
- Logs: `.platform/api/logs/<handle>.log`

## What lives where

- `yeshuman.yaml` — handle, ports, modules, seeds, flags.
- `config/api.json`, `config/ui.json` — tenant config (features, copy, theme, nav).
- `plugin/django/` — tenant-owned Django apps (`PLUGIN` in `__init__.py`). Import platform symbols from `yeshuman.sdk` only.
- `plugin/labs/` — tenant-owned Labs routes, nav and components (`index.ts`). Import platform symbols from `@yeshuman/sdk` only.
- `seeds/` — demo users and other pack-owned seed files. Manifest `seeds:` is the command list.

## Pack or platform?

If the request can be met with config, theme, seeds or a pack plugin using the extension points the platform already offers, change **this repo** and open a PR here. If it needs a new extension point or a change to shared behaviour, it is a **platform** change: do not edit `.platform/`. Prototype it there if useful, then open an issue on this repo labelled `platform-request` from `.github/ISSUE_TEMPLATE/platform-request.md`: what's needed, why, what it blocks, and the proposed slot or contract. If GitHub issue creation fails (the Cloud token may lack Issues permission), put the same text under `## Platform request` in the body of the pack PR that needs it. Yes Human picks up both, links the platform PR and the product contract version on your issue or PR, and you then raise the pin in the PR whose feature needs it (saying why under `## Platform pin`) and merge. A pure catch-up goes in its own PR (`yeshuman-platform-upgrade`). See `yeshuman-platform-request`.

Install the `yeshuman-pack` Cursor plugin (team marketplace) for the detailed skills.

Until team marketplace Cloud attach works, the same `yeshuman-*` skills and `platform-readonly` rule are also committed under `.cursor/skills/` and `.cursor/rules/` so Cloud Agents load them from this clone. Do not edit those copies; they are Yes Human template files.
