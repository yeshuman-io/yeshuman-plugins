---
name: yeshuman-linear-evidence
description: Post evidence on the Linear issue for any change you build, fix or report on — a screenshot or short video for UI, request/response or test output for backend, before/after queries for data, deploy plus health check for config — with a Given/When/Then "How to verify" block that a human can follow, mirrored in the PR body. Use whenever your work is tied to a Linear issue, before you mark a PR ready or self-merge, and when reporting status back to an issue.
---

# Evidence on the Linear issue

If your work is tied to a Linear issue, you must post evidence on that issue. A claim without evidence counts as unverified. The PR body carries the same "How to verify" block. For user-visible changes, `yeshuman-pack-feature` (Merge) requires the evidence before a self-merge. It goes on the Linear issue, or in the PR body when Linear is unreachable (section 6).

## 1. Pick the evidence

Choose by the kind of change. If a change spans several kinds, include one piece for each.

| Change | Evidence | Minimum |
|--------|----------|---------|
| UI (static: copy, theme, layout, a page) | Screenshot | The changed screen at `labs_port`, logged in as the relevant persona. Include a before shot when the change is visual. |
| UI flow (several steps, forms, chat, navigation) | Short video | 10–60 s covering the flow from start to finished state. Add a screenshot of the end state too, because Linear shows images inline. |
| Backend / API | Request and response, or test output | `curl -i` against the endpoint with the status line and a trimmed body, or the `pytest` summary for the touched app (the command plus the final pass/fail lines). |
| Agent tool / chat behaviour | Transcript excerpt and screenshot | The prompt, the tool call or result, and the reply. Use the API log lines (`.platform/api/logs/<handle>.log`) if the UI does not show the tool call. |
| Data / migration / seeds | Before/after query | The same query run before and after `migrate` or the seed command: row counts or the affected rows. |
| Config / infra / deploy | Deploy and health check | The Railway deployment status for each service on the head SHA, plus `curl -fsS <api>/health` (and `/ping`), `<ui>/health.json`, and a working login. |

Never include secrets, tokens, real client personal data, or full env dumps. Redact them and say you redacted them. Use the demo personas or the default Cloud login.

## 2. Capture it in Cursor Cloud

Save everything under `/opt/cursor/artifacts/` (Cursor shows that folder to the user) with short descriptive names, for example `tc-123-candidate-card.png`, `tc-123-apply-flow.mp4`, `tc-123-api.txt`.

- **Stack:** `bash .platform/scripts/pack_workspace/run.sh`, then open `http://localhost:<labs_port>` (ports are in `yeshuman.yaml`).
- **Screenshots and video:** use the Cloud desktop through your computer-use or browser tool, and its screen recording for flows. Record only the flow, not the setup. With no desktop, a headless browser (for example `npx playwright screenshot --full-page <url> out.png`, if Playwright is installed) covers pages that need no login.
- **API:** `curl -sS -i -X POST http://localhost:<api_port>/api/... -H 'Content-Type: application/json' -d '{...}' | tee /opt/cursor/artifacts/<id>-api.txt`. Authenticated calls use the same login as Labs. Trim large bodies with `head`.
- **Tests:** `... pytest <path> -q 2>&1 | tail -n 30 | tee /opt/cursor/artifacts/<id>-tests.txt`.
- **Data:** run the query through the platform's manage.py shell (`DOTENV_FILE=.env.<handle>`) or `psql` against the local tenant database, before and after, into one `.txt`.
- **Railway:** the preview and staging URLs are in the Railway bot comment and the deployment status on the PR (`gh pr view <n> --comments`, `gh pr checks <n>`). Health: `curl -fsS https://<api-host>/health`.

Capture on the **final head SHA**. If you push again, recapture anything the push could change.

## 3. Post it on the issue

Post one comment per milestone: when the PR is ready, and again after merge if the staging check adds anything. Upload the files so they show inline. Do not link to `/opt/cursor/artifacts` paths, because nobody else can open them.

**Linear MCP available** (a `linear-*` MCP with `prepare_attachment_upload`). Do one file at a time; the signed URL expires in 60 s.

1. `prepare_attachment_upload` with `issue`, `filename`, `contentType`, `size` (exact bytes: `stat -c %s <file>`).
2. `curl -X PUT --data-binary @<file>` to `uploadRequest.url`, sending **every** header from `uploadRequest.headers` verbatim. A changed or missing header gives a 403.
3. `create_attachment_from_upload` with `issue` and `assetUrl`.
4. When every file is uploaded, call `save_comment` with `issueId` and the comment body (template below), embedding images as `![name](assetUrl)` and other files as `[name](assetUrl)`.

**No MCP:** use the Linear API with the pack's key through the bundled helper. It is stdlib Python, never prints the key, uploads and attaches each file, then posts the comment. In the body, `{{file:<basename>}}` is replaced with the uploaded file.

```bash
H=.cursor/skills/yeshuman-linear-evidence/linear_evidence.py
python3 $H --issue ABC-123 --check            # key + issue lookup only
python3 $H --issue ABC-123 \
  --file /opt/cursor/artifacts/abc-123-card.png \
  --file /opt/cursor/artifacts/abc-123-api.txt \
  --comment /tmp/abc-123-evidence.md
```

The key is read from `LINEAR_API_KEY`, then `<HANDLE>_LINEAR_API_KEY` (handle from `yeshuman.yaml`), or from `--key-env NAME`. Linear personal keys are sent without `Bearer`. A 401 means the key is expired or belongs to another workspace. "Entity not found" means a wrong identifier or a team the key cannot see. Neither is something you can fix: report it (step 6).

## 4. Comment template

`{{file:...}}` placeholders are for the helper. On the MCP path, write the `![name](assetUrl)` links yourself.

```markdown
## Evidence: <one-line summary of what changed>

**PR:** <PR URL> (head `<short sha>`) · **Preview:** <Railway preview Labs URL> · **Status:** ready for review | merged to staging

### What changed
- <one to three bullets, matching the diff; claim no more than it does>

### Evidence
{{file:abc-123-card.png}}
- API: `POST /api/...` → `201` ({{file:abc-123-api.txt}})
- Tests: `pytest plugin/django/<app>/tests -q` → `12 passed`

### How to verify
**Given** <starting state: environment URL, persona/login, any data>
**When** <the action, step by step>
**Then** <what the human should see, exactly>

<!-- Add one Given/When/Then per acceptance criterion; two or three is typical. -->

### Not verified
- <anything you could not check, and why; or "Nothing">
```

Keep "How to verify" human-runnable. Use the Railway preview or staging URL, not `localhost`, and real persona names or the default login. Give clicks and inputs, not code. Write one scenario per acceptance criterion on the issue, in the same words where possible.

## 5. Same block in the PR body

The PR body carries the same **What changed**, **How to verify** (identical Given/When/Then) and **Not verified** sections. Add a link to the Linear issue and the evidence comment. Images can be embedded with the same `assetUrl`s. If the issue has no Linear link (no issue), put the evidence in the PR body only.

## 6. When you cannot capture evidence

Say so explicitly, in the comment and the PR. Do not fake it.

- Never stage, mock up, edit or reuse a screenshot, log or response to stand in for one you did not capture on this change. Never describe a check you did not run as if you had run it.
- Under **Not verified**, write what is missing and why, for example: "No screenshot: Labs failed to start (`run.sh` error in the log, excerpt attached)" or "Railway preview API failed to deploy; local verify only."
- **Linear unreachable** (no MCP, missing key, 401, or the key cannot see the team): put the full evidence and the "How to verify" block in the PR body instead. That counts for self-merge. Embed screenshots and videos in the PR body. The Cursor PR tool uploads `<img>`/`<video>` tags that point at `/opt/cursor/artifacts/` paths; paste text evidence inline in fenced blocks. Add this line at the top of the PR body: `Linear evidence pending: <ISSUE-ID>: <reason>` (for example "<HANDLE>_LINEAR_API_KEY returns 401"). Say the same in your final report.
- **Post later.** Once Linear access works, any agent on this pack (or a human) posts the evidence comment from the PR body using this skill. Then they replace the pending line with `Linear evidence: <comment URL>`. At the start of a run, check your own merged PRs for a pending line and clear any you can.
- A user-visible change with no evidence anywhere (neither on the issue nor in the PR body) is not eligible for self-merge. Leave the PR open and say what is missing.
