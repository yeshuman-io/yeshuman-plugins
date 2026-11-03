---
name: yeshuman-pack-orientation
description: Orient in a Yes Human tenant pack — what the pack is, how the read-only platform in .platform/ relates to it, how to install and run the stack, how to decide whether a request is a pack change or a platform change, and when a request first needs a design record (yeshuman-ontology-steward). Use at the start of any task in a repo that has yeshuman.yaml at its root.
---

# Yes Human pack orientation

## Two layers

| Layer | Where | Who changes it |
|-------|-------|----------------|
| **Pack** (this repo) | `yeshuman.yaml`, `config/`, `plugin/`, `docs/ontology/` | You, via PRs on this repo |
| **Platform** | `.platform/` (clone of the Yes Human platform, replaced on every install) | Yes Human only |

The platform is one codebase serving many tenants. It loads exactly one pack at runtime (`TENANT_ROOT` points at this repo) and reads the pack's config and plugins through fixed extension points. Nothing tenant-specific belongs in the platform.

## Install and run

1. `bash .cursor/install.sh` — clones the platform at `YESHUMAN_PLATFORM_REF` (default `master`) into `.platform/` using `YESHUMAN_PLATFORM_TOKEN`, then installs dependencies, the database and seeds for this pack's handle. Cursor Cloud runs this on boot.
2. `bash .platform/scripts/pack_workspace/run.sh` — starts API and UI. Ports are `api_port` / `ui_port` in `yeshuman.yaml`.
3. Check: `cd .platform/cli && uv run yeshuman verify <handle>`. Logs: `.platform/api/logs/<handle>.log`.

Default login is `cloud@yeshuman.local` / `clouddev` unless `YESHUMAN_SEED_DEPLOYMENT_USERS` is set.

If install fails on the clone step, the Cloud secret `YESHUMAN_PLATFORM_TOKEN` is missing or cannot read the platform repo — report that; do not work around it.

## Platform version (every session start)

After install, before any task:

```bash
python3 .platform/scripts/pack_workspace/contract_status.py
```

- `current`: carry on.
- `behind` or `mismatch`: the pack's `requires_product` floor is older than the platform on `staging`. Do the catch-up **first, as its own PR** (`yeshuman-platform-upgrade`), then the task. If the task itself needs the newer contract, raise the floor in the feature PR instead and say why under `## Platform pin` (`yeshuman-pack-feature`). Skip it when `yeshuman.yaml` has `platform_pin:`, an open `Platform catch-up:` PR already exists, or the user says the client is near a release. Say which in your report.
- `incompatible` or `missing`: stop and file `agent-feedback` with the output. Never raise the `<N+1` cap: majors are rolled out by Yes Human.

If the script is not in `.platform/`, the platform ref predates it: note that and carry on.

## Browser checks and Railway

- Computer use is not reliably available in Cloud. If it is missing or capped, drive the browser with a script instead: Puppeteer or Playwright from Node (`npx -y puppeteer` / `npx -y playwright` against `http://localhost:<ui_port>`), or Chrome DevTools Protocol. Save screenshots as evidence (`yeshuman-linear-evidence`).
- Never use Railway MCP, the Railway CLI with account tokens, or `railway variable list`. Read deploys from Railway's comments and commit statuses on the PR, and check the deployed URLs with `uv run --with pyyaml deploy/smoke.py --api <api-url> --ui <ui-url>` (health, `bootstrapped`, UI, one demo login).
- `seeds/demo.yaml` users exist on staging and PR environments, never in production. Their passwords are committed, so do not add real stakeholder accounts there for production use.

## What is it? (before pack or platform)

Ask first: which existing platform abstraction is this? If the request would add a model, app or migration, a classifier profile, a config key, a hardcoded list or copy in code, a `plugin/shared` spec, an agent tool, or a new UI noun, or arrives in product words with no record named, run `yeshuman-ontology-steward` before anything else. It maps the request onto the platform nouns (`.platform/docs/ONTOLOGY_DOC_MAP.md`) and this pack's past decisions (`docs/ontology/decisions.md`, `docs/ontology/vocabulary.md`), and ends with a design record. "The pack is allowed to add a table" is not the same as "this needs a table".

## Pack or platform?

Then ask: can this be done with what the platform already exposes?

- **Pack change** — copy, theme, nav, feature flags, landing (`config/ui.json`); tool catalog, features, integrations settings (`config/api.json`); modules, seeds, compositions (`yeshuman.yaml`); tenant-owned Django apps and UI pages through the plugin slots (`plugin/`). Build it here, run it, open a PR on this repo. Use `yeshuman-pack-feature`.
- **Platform change** — needs a new extension point, a new config key the platform does not read, a change to shared behaviour, a shared model or API, or a bug in platform code. Do not edit `.platform/` for real. Use `yeshuman-platform-request`.
- **Both** — build the pack part now; raise a platform request for the missing piece and say in the pack PR what it waits on.

When unsure, grep `.platform/` for the config key or slot you need. If the platform does not read it, it is a platform change.

## Skills in this pack

Cloud loads skills from this clone's `.cursor/skills/` until the `yeshuman-pack` plugin attaches from the team marketplace. Those folders hold three tiers: `yeshuman-*` skills (managed, overwritten on refresh), approved adopted skills (currently none), and unprefixed pack-owned skills (never touched by refresh; must not duplicate or override a `yeshuman-*` skill). See `yeshuman-pack-feature` (Skill tiers).

- Use `yeshuman-pack-orientation`, `yeshuman-ontology-steward` (design record before any new noun, table, config key or hardcoded list), `yeshuman-pack-feature`, `yeshuman-pack-tools` (agent tool contract), `yeshuman-platform-request`, `yeshuman-platform-upgrade` (catch the pin up to the latest platform minor in its own PR), `yeshuman-linear-evidence` (post evidence and a Given/When/Then "How to verify" on the Linear issue and the PR for any issue-linked work), and `yeshuman-plan-to-make-a-plan` (plan a Linear issue with the user before building; `/yeshuman-plan-to-make-a-plan`). Always the fully qualified `yeshuman-*` names; never `yh-*`.
- Do not add other platform skills here (`create-domain-slice`, `create-django-app`, or anything else from `.platform/.cursor/skills`) unless Yes Human approved them. They belong in the platform. Read them from `.platform/` if you need them; do not copy them into this pack.
- `.cursor/*` is managed, except pack-owned skills. `AGENTS.md`, `CLAUDE.md`, `.github/ISSUE_TEMPLATE/*` and `.github/pull_request_template.md` are managed too. If you are tempted to rewrite install, environment, Dockerfile, rules, or `yeshuman-*` skills, file an `agent-feedback` issue on this pack and stop.

## Fresh skills (orchestrators and workers)

- A long-running orchestrator may hold stale skills, because skills refresh on `staging` while it runs. Before creating workers, run `git pull origin staging` and `ls .cursor/skills/yeshuman-*` so you know what is current.
- Name the relevant skills explicitly in every worker kickoff, for example "use `yeshuman-pack-feature` and `yeshuman-linear-evidence`". Do not assume the worker will find them. When the work adds a noun, pass the design record (`yeshuman-ontology-steward`) in the kickoff, not just the stakeholder's message.
- If a skill does not show as a slash command, read `.cursor/skills/<name>/SKILL.md` directly and follow it.
