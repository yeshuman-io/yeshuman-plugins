---
name: yeshuman-platform-request
description: Raise a Yes Human platform change from a tenant pack — a platform-request issue on the pack from the template (what's needed, why, what it blocks, proposed slot or contract), or, if GitHub issue creation fails, a "## Platform request" section in the pack PR body. Covers how Yes Human picks it up and what to do when the platform PR lands. Use when yeshuman-pack-orientation decides the work needs a new extension point, a contract change or a platform fix.
---

# Raise a platform request

Pack agents cannot change the platform. Yes Human builds platform changes on the platform's `staging` branch so every tenant stays on one codebase. The fleet agent watches every pack for requests, mirrors them into Yes Human's Linear, builds the reasonable ones, and tells you when they land.

## 1. Prove the need

- Confirm the pack cannot do it: grep `.platform/` for the config key, plugin slot, API or page you need.
- Optional: prototype in `.platform/`, run the stack and show it works. Keep it tenant-neutral (no tenant names, handles or branding in platform code). Never commit or push from `.platform/`.

## 2. Write the request

Use the template at `.github/ISSUE_TEMPLATE/platform-request.md` (four sections). Keep it short:

```markdown
## What's needed
The platform capability, not the tenant feature. Tenant-neutral.

## Why
What the pack is trying to do and why config, seeds or a pack plugin cannot do it (what you grepped).

## Blocking
The pack PR, issue or Linear issue waiting on this, or `none`.

## Proposed slot or contract
The extension point, config key, API fields or behaviour, and what the pack does once it exists.
Diff in <details> if you prototyped (`git -C .platform diff`), plus `git -C .platform rev-parse HEAD`.

Requested by: <your Cursor agent URL>
```

## 3. File it: issue first, PR body as fallback

**Issue on this pack** (preferred):

```bash
awk 'f; /^---$/ && ++n == 2 { f = 1 }' .github/ISSUE_TEMPLATE/platform-request.md > /tmp/request.md   # then fill it in
gh issue create --label platform-request --title "Platform: <short capability>" --body-file /tmp/request.md
```

**If that fails** (for example `Resource not accessible by integration` or HTTP 403: the Cursor GitHub App token in Cloud often has no Issues permission, or the label is missing), do not retry with other tokens and do not stop. Put the same text in the body of the pack PR that depends on it, under a heading that is exactly:

```markdown
## Platform request

### What's needed
...
### Why
...
### Blocking
This PR.
### Proposed slot or contract
...
Requested by: <your Cursor agent URL>
```

If there is no pack PR yet, open one now against `staging` with the pack-side work started (or a draft with only the pack plan) and the section above, and leave it draft. Say in your report which path you used.

Either path is picked up: the fleet scans pack issues labelled `platform-request` and open pack PR bodies for `## Platform request`.

## 4. While you wait

- Ship any pack-only part. Code against the proposed contract with a fallback (feature-detect the slot or field) so the pack still works on the current platform.
- Do not edit `.platform/` for real, and do not copy platform code into the pack.
- Watch the issue or PR for a comment from Yes Human. It links the platform PR and gives the product contract version.

## 5. When the platform PR lands

The comment tells you the version, for example "merged to platform `staging`, product contract 2.4.0". Then:

1. Re-run `bash .cursor/install.sh` (or start a new agent) so `.platform/` has the change.
2. Catch the pin up in its own PR (`yeshuman-platform-upgrade`): `contract_status.py --write` sets both pins to `>=<version minor>,<<next major>>` (for example `>=2.4,<3`). Merge that first. If the pin change is the only thing the request needed, that PR is the whole fulfilment.
3. Rebase the feature PR on the new `staging`, drop any fallback you no longer need, verify as usual (`yeshuman-pack-feature`), then mark it ready and merge it to `staging` under the self-merge bar. Remove `## Platform request` from the PR body only if Yes Human says it is fulfilled, and close the issue if you opened one.

If Yes Human declines or changes the proposal, the comment says why and what to do instead.
