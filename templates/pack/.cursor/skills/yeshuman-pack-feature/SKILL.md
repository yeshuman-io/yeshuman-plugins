---
name: yeshuman-pack-feature
description: Build a feature or change inside a Yes Human tenant pack using the platform's extension points — yeshuman.yaml, config/api.json and config/ui.json, and the Django and Labs plugin contracts — then run and verify it against the read-only platform, open the PR with evidence (yeshuman-linear-evidence), and self-merge to staging only when the high-confidence bar is met. Use once yeshuman-pack-orientation has decided the work is a pack change.
---

# Build in a Yes Human pack

## Before you start: catch up first

If `yeshuman-pack-orientation` reported the pack as `behind` or `mismatch`, the catch-up (`yeshuman-platform-upgrade`) goes first, in its own PR, merged to `staging` before this work starts. **Never put a `requires_product` / `requiresProduct` change in a feature PR.** A feature that needs a newer platform slot waits for the catch-up to merge, then branches from the new `staging`.

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
from yeshuman.sdk import PluginConfig

PLUGIN = PluginConfig(
    apps=(),          # extra INSTALLED_APPS (tenant-owned apps under plugin/django/<app>/)
    routers=(),       # Ninja routers mounted by the host
    tools={},         # { focus: [tool, ...] } agent tools
    facts=(),         # chat-suggestion providers
    catalog={},       # tool-catalog labels
    mapper={},        # SSE write mappings
    hooks={},         # core extension points (names in .platform/api/yeshuman/extensions.py)
    requires_product=">=2.4,<3",   # same range as requiresProduct in plugin/labs/index.ts
)
```

Seeds are listed in `yeshuman.yaml` `seeds:`, not here.

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

If the slot you need does not exist, stop: that is a platform request. Follow `yeshuman-platform-request`: a `platform-request` issue on this pack, or a `## Platform request` section in this PR's body if issue creation fails.

## Canvases on pages you do not own (product contract 2.5.0)

To add a canvas or a full-page report or view to a platform-owned page (for example `/platform/skills-catalog`) or to an entity the platform shows, register it. Do not edit the page in `.platform/`, and do not rebuild the page in the pack.

```ts
app.canvases?.register({
  id: '<handle>.skill-pool',                         // prefix with your handle
  title: 'Skill pool',
  targets: [{ page: '/platform/skills-catalog' }, { entity: 'skill-domain' }],
  page: { path: '/platform/skill-pool' },            // optional: same view as a deep-linkable full page
  requiresProduct: '>=2.5.0,<3',
  render: SkillPoolCanvas,                           // gets canvasId, mode, params, entity, data, pagePath, close
  glance: SkillPoolGlance,                           // optional summary strip under the page header; gets open(), pagePath
})
```

- A `page` target (a route pattern; `:id` params reach the canvas) adds a launcher to that page's header and renders your `glance` under it, and `?canvas=<id>` opens it. Set `launcher: false` when the glance has its own button. An `entity` target adds a launcher wherever the platform renders `PluginCanvasLaunchers` for that kind. The current kinds and pages are listed in `.platform/docs/TENANT_REPOS.md` § Pack canvases.
- `render` fetches its own data from your pack routes or existing platform APIs with `authorizedFetch`. Lay it out with `ArtifactCanvasBody` when `mode` is `canvas`, and as page content when `mode` is `page`.
- Open a registered canvas from your own pages with `useOpenPluginCanvas()(id, { entity, data })`. Prefer this to calling `openCanvas` with ad hoc content when the same view is offered from more than one place.
- Raise `requiresProduct` (in the manifest and in `plugin/labs/index.ts`) to the contract that added any target you use. A manifest the platform cannot satisfy is skipped, not an error.
- Need a target the platform does not render yet (a new entity kind or row)? That is a platform request for a launcher placement, not a new slot.

## Verify

1. Restart the stack: `bash .platform/scripts/pack_workspace/run.sh`.
2. `cd .platform/cli && uv run yeshuman verify <handle>`.
3. Labs type-check: `cd .platform/labs && pnpm type-check`.
4. Exercise the change in the browser on `labs_port`, and capture evidence as you go (`yeshuman-linear-evidence`: screenshot or video for UI, request/response or test output for backend).

## Ship

Commit only pack files (`.platform/` is git-ignored). Open a PR against `staging` describing the change, how you verified it (commands and results), the Railway preview link, and any platform request it depends on. Include the Given/When/Then "How to verify" block from `yeshuman-linear-evidence`. If the work is tied to a Linear issue, post the evidence comment on the issue too.

## Skill tiers

Pack `.cursor/skills/` has three tiers:

| Tier | Names | Owner | On template refresh |
|------|-------|-------|--------------------|
| Yes Human | `yeshuman-*` (never `yh-*`) | Yes Human, from `yeshuman-plugins` | Overwritten |
| Adopted third-party | Original name, on the approved list (currently empty) | Yes Human approves | Kept |
| Pack-owned | Unprefixed, written for this pack | The pack | Never touched |

A pack-owned skill must not duplicate or override a `yeshuman-*` skill. Extend it by linking to the `yeshuman-*` skill and adding pack-specific detail, and do not restate or contradict its rules. You may write pack-owned skills. If one looks reusable across packs, also suggest it as a platform request (`yeshuman-platform-request`) or a skill request (an `agent-feedback` issue on this pack naming the skill). This is a recommendation, not a merge requirement. A copy of a platform skill (`.platform/.cursor/skills`) is not pack-owned: it needs approval as an adopted skill.

## Merge

You may squash-merge your own PR to `staging` only when **all** of these hold. CI is not required; your own runs are the evidence. Never merge or push to `master`: promotion to production is done by Yes Human's fleet coordinator, not by implementer agents.

- Base is `staging`; the branch is cut from current `staging` with no unmerged parent PR (not stacked); the PR is not draft.
- Small: roughly 15 files and 800 changed lines or fewer, excluding tests.
- Pack files only (`plugin/`, `config/`, `seeds/`, `yeshuman.yaml`, pack-owned skills in `.cursor/skills/<unprefixed>/`). No `.platform/`, no copied platform code, no managed files (`.cursor/*` other than pack-owned skills, `deploy/*`, `.dockerignore`, `AGENTS.md`), no edits to `yeshuman-*` skills, and no new adopted skill without approval (see Skill tiers).
- Any platform slot it needs is already on platform `staging`, and the pack's pin already covers it (from a merged catch-up PR; this PR does not change the pin).
- On the final head SHA, in your Cloud environment: install, `run.sh`, `yeshuman verify <handle>`, the pack tests for touched apps (new behaviour has a test), and `pnpm type-check` plus a browser check if Labs changed.
- New migrations are additive, take the next number after `staging`, and no other open PR on this repo uses the same app and number.
- The Railway PR preview is deployed on the head SHA, every service is green (api, ui, jobs if present), and `deploy/smoke.py` passes against it (health, `bootstrapped`, Labs loads, a demo login works). If PR previews do not deploy for this pack, say so in the PR and run the smoke check against `staging` after merging. A pin-only catch-up PR (`yeshuman-platform-upgrade`) may merge on its local tests while PR environments can't deploy, followed by the post-merge `staging` smoke check. Feature PRs still need the preview.
- No open review or comment asks for changes or a hold.
- User-visible change (anything a person sees or does differently in Labs, the API or agent chat): the evidence comment from `yeshuman-linear-evidence` is posted on the Linear issue for the head SHA, and the PR body has the same "How to verify" block. If Linear is unreachable (no MCP, bad key), the full evidence plus "How to verify" in the PR body counts instead. The PR must state `Linear evidence pending: <issue>: <reason>`, and the evidence is posted to Linear once access works. With no Linear issue, the PR body carries the evidence. "Not verified" items are fine to list, but no evidence for the change itself blocks a self-merge.

**Squash only.** Merge with `gh pr merge <n> --squash`, or through the API with `merge_method=squash`. The PR title becomes the commit title. Never use a merge commit or a rebase merge; `staging` history stays one commit per PR.

Otherwise leave the PR open and say what is missing. Always ask first for: auth, billing, outbound email or SMS, integrations or secrets, migrations that alter or drop existing data, or anything you are unsure about. After merging, confirm the `staging` deploy is green; if it is not, open a revert or fix PR straight away.
