---
name: yh-platform-request
description: Raise a Yes Human platform change from a tenant pack — prototype in the read-only .platform/ checkout if useful, then file a platform-request issue on the pack with the problem, proposed change and diff. Use when yh-pack-orientation decides the work needs a new extension point or a change to shared platform behaviour.
---

# Raise a platform request

Pack agents cannot change the platform. Yes Human reviews requests and lands platform changes so every tenant stays on one codebase.

## 1. Prove the need

- Confirm the pack cannot do it: grep `.platform/` for the config key, plugin slot or API you need.
- Optional but valuable: prototype the change in `.platform/`, run the stack, and show it works. Keep it minimal and tenant-neutral — no tenant names, handles or branding in platform code; tenant specifics stay in the pack and reach the platform through config or a slot.

## 2. File the issue on this pack

```bash
git -C .platform diff > /tmp/platform.diff   # if you prototyped
gh issue create --label platform-request \
  --title "Platform: <short capability, not the tenant feature>" \
  --body-file /tmp/request.md
```

`/tmp/request.md`:

```markdown
## Need
What the tenant is trying to do and why the pack cannot do it today.

## Proposed platform change
The extension point, config key or behaviour to add or change. Tenant-neutral.

## Pack side
What this pack will do once it exists (config / plugin code).

## Prototype
Platform ref: <git -C .platform rev-parse HEAD>
<details><summary>Diff</summary>

```diff
(paste /tmp/platform.diff)
```

</details>

## Verified
How you ran it and what you checked.
```

If the `platform-request` label is missing on the repo, report it rather than filing without it — Yes Human only picks up labelled issues.

## 3. Continue

- Do not wait on the platform: ship any pack-only part as a PR and link the issue.
- Discard the prototype; the next install replaces `.platform/`.
