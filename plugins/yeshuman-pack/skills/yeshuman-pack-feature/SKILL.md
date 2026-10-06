---
name: yeshuman-pack-feature
description: Build a feature or change inside a Yes Human tenant pack using the platform's extension points — yeshuman.yaml, config/api.json and config/ui.json, and the Django and Labs plugin contracts — then run and verify it against the read-only platform, open the PR, and self-merge to staging only when the high-confidence bar is met. Use once yeshuman-pack-orientation has decided the work is a pack change.
---

# Build in a Yes Human pack

## Layout

```
yeshuman.yaml        # handle, domain, ports, modules, plugin, seeds, services, flags, compositions
config/api.json      # API slice: features, tool catalog, integrations
config/ui.json       # Labs slice: theme, copy, nav, landing
plugin/django/       # PLUGIN = PluginConfig(...) in __init__.py; tenant-owned apps in plugin/django/<app>/
plugin/labs/         # register(app) in index.ts; tenant-owned pages in plugin/labs/<app>/
```

## Prefer config over code

Theme, copy, nav, landing content and feature flags are **config**. Reach for `plugin/` only when config cannot express the change.

## Django plugin — `plugin/django/__init__.py`

```python
from yeshuman.plugin import PluginConfig

PLUGIN = PluginConfig(
    apps=(),          # extra INSTALLED_APPS (tenant-owned apps under plugin/django/<app>/)
    routers=(),       # Ninja routers mounted by the host
    tools={},         # { focus: [tool, ...] } agent tools
    facts=(),         # chat-suggestion providers
    seeds=(),         # extra management command names
    catalog={},       # tool-catalog labels
    mapper={},        # SSE write mappings
    requires_product="0.1.0",
)
```

New tenant-owned models need migrations in the app's own `migrations/` folder. Generate them with the platform's manage.py pointed at this pack (`TENANT_ROOT` is set by the install).

## Labs plugin — `plugin/labs/index.ts`

```ts
export function register(app: YeshumanPluginApi) {
  app.routes.add({ path: '/example', element: ExamplePage })
  app.dashboard.section('patient', 'example')   // DashboardSectionName in .platform/labs/src/plugin/types.ts
  app.chrome.card({ hideDescription: true })
  app.publicShare.route({ path: '/s/:slug', element: PublicExamplePage })
}
```

The slots are defined by `YeshumanPluginApi` in `.platform/labs/src/plugin/types.ts`; read it for the current list. Labs builds alias `@tenant/plugin` and `@tenant/ui-config` to this pack. Use the platform's shared components and design tokens; do not copy platform components into the pack.

If the slot you need does not exist, stop: that is a platform request.

## Verify

1. Restart the stack: `bash .platform/scripts/pack_workspace/run.sh`.
2. `cd .platform/cli && uv run yeshuman verify <handle>`.
3. Labs type-check: `cd .platform/labs && pnpm type-check`.
4. Exercise the change in the browser on `labs_port`.

## Ship

Commit only pack files (`.platform/` is git-ignored). Open a PR against `staging` describing the change, how you verified it (commands and results), the Railway preview link, and any platform request it depends on.

## Merge

You may squash-merge your own PR to `staging` only when **all** of these hold. CI is not required; your own runs are the evidence. Never merge or push to `master`: promotion is Yes Human's.

- Base is `staging`; the branch is cut from current `staging` with no unmerged parent PR (not stacked); the PR is not draft.
- Small: roughly 15 files and 800 changed lines or fewer, excluding tests.
- Pack files only (`plugin/`, `config/`, `seeds/`, `yeshuman.yaml`). No `.platform/`, no copied platform code, no managed files (`.cursor/*`, `deploy/*`, `.dockerignore`, `AGENTS.md`). `.cursor/skills/` holds only the `yeshuman-*` skills.
- Any platform slot it needs is already on platform `staging`, and `requires_product` / `requiresProduct` matches.
- On the final head SHA, in your Cloud environment: install, `run.sh`, `yeshuman verify <handle>`, the pack tests for touched apps (new behaviour has a test), and `pnpm type-check` plus a browser check if Labs changed.
- New migrations are additive, take the next number after `staging`, and no other open PR on this repo uses the same app and number.
- The Railway PR preview is deployed on the head SHA, every service is green (api, ui, jobs if present), Labs loads and login works.
- No open review or comment asks for changes or a hold.

Otherwise leave the PR open and say what is missing. Always ask first for: auth, billing, outbound email or SMS, integrations or secrets, migrations that alter or drop existing data, or anything you are unsure about. After merging, confirm the `staging` deploy is green; if it is not, open a revert or fix PR straight away.
