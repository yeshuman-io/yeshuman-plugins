---
name: yeshuman-agent-actions
description: >-
  Declare, change or review what the agent can do in a Yes Human tenant pack: domain actions in
  plugin/django/<app>/actions.py, listed in PLUGIN.actions and rendered as <domain>_read / _write /
  _delete tools for the in-app agent, MCP and voice. Use when adding or renaming an agent
  capability, wiring a pack's actions or foci, writing a prompt or config that points at a
  capability, or fixing a check_actions or terminology failure.
---

# Agent actions in a pack

Normative: `.platform/docs/AGENT_ACTIONS.md`. Naming tables:
`.platform/docs/agent-actions/naming-platform.md` (core) and this pack's
`docs/agent-actions/naming.md`. A new domain or action is a new noun, so it goes through
`yeshuman-ontology-steward` first.

## Before you write code

1. **Pick the noun from the model.** The domain noun is the plural of the app's aggregate root
   (`Memory` → `memories`) or an ontology noun. Never a screen label, grouping or scope word
   (`lexicon`, `system`, `admin`, `manage`, `identity`, `library`, `board`, …: full denylist in
   `.platform/api/yeshuman/actions/naming.py`). A core noun is never redeclared by a pack.
2. **Add a row to `docs/agent-actions/naming.md`** for every new domain or action, with its kind
   and scope.
3. **Kind:** READ (no change), WRITE (undoable change), DESTRUCTIVE (removes, ends, supersedes,
   or changes how others are scored or served), UI (in-app screen only). Toggles of the acting
   user's own markers (vote, pin, save) are WRITE. A WRITE that exposes or notifies others sets
   `confirm=True`. When unsure, DESTRUCTIVE.
4. **Scope:** `SELF` (own rows), `ORGANISATION` (active organisation), `TENANT` (operator), declared
   per focus on the domain. One action name serves every scope; the handler reads `ctx.scope`.

## Declare

```python
# plugin/django/<app>/actions.py
from pydantic import BaseModel, Field
from yeshuman.sdk import READ, WRITE, SELF, TENANT, ANY_FOCUS, ActionContext, ActionFailedError, ActionResult, EntityChange, action, domain

NOUNS = {"memories": Memory}

memories = domain("memories", label="memories", speak_as="checking your memories",
                  menu_group="you", foci={ANY_FOCUS: SELF})

class MemorySearch(BaseModel):
    q: str | None = Field(default=None, description="What to look for.")
    limit: int = Field(default=10, ge=1, le=50)

@action(memories, name="search", kind=READ, input=MemorySearch, result=MemoryList,
        description="Find saved memories by meaning. Example: q='interview times'.")
async def search(ctx: ActionContext, data: MemorySearch) -> ActionResult:
    rows = await services.asearch(ctx.user, data.q, data.limit)
    return ActionResult.success(f"Found {len(rows)}.", data=MemoryList(items=...))
```

- **Inputs** never contain `user`, `user_id`, `thread_id`, `focus`, `current_route`,
  `organisation_slug`, `active_organisation_slug`, `run_id`, `tenant`, `action`, `args`, `confirm`.
  Use `ctx.user`, `ctx.thread_id`, `await ctx.organisation()`, `ctx.scope`, `ctx.extras`.
- **Results** are `ActionResult.success(summary, data=<typed model>, entities=[EntityChange(type=
  "memory", id=..., label=..., change="created", route="/memories/<id>")])`. Every write lists what it
  changed: entities drive chat pills, list refresh, thread activity and links. No emoji, no
  "Error:" strings.
- **Token budget:** every rendered tool is sent on every model call. Keep field descriptions to
  a few words, leave fields an agent does not need off the input model, and reserve
  `foci={ANY_FOCUS: ...}` for capabilities every focus genuinely needs; list specific foci
  otherwise. In-app-only domains set `protocols=("graph",)`.
- **Expected failures:** `raise ActionFailedError("No such memory.", fix="Search first, then pass its id.", code="not_found")`.
- **Descriptions:** purpose and one example, ≤ 400 characters, no tool names. Point at another
  capability as `domain.action`.
- **Gates:** `enabled=` (settings feature flag), `available_when=` (per user, async).
- **Facts for MCP:** a `facts.py` provider with `mcp_resource = True` (and `title`, `description`,
  `foci`) is served at `facts://<id>`. Glossaries belong there, not in an `explain` action.
- Import only from `yeshuman.sdk`; never from platform `apps.*` modules.

## Wire it into the pack

- List action modules in `PLUGIN.actions = ("<app>.actions",)` in `plugin/django/__init__.py`.
- Give a core domain to a pack focus: `PLUGIN.foci = {"organisations": {"employer": "organisation"}}`.
- Extend a core domain only at a declared extension point:
  `@action(get_domain("files"), name="extract_cv", extends="inspect", ...)`. If the extension
  point you need does not exist, that is a platform request (`yeshuman-platform-request`), not a
  pack-local copy of the core domain.
- Prompts, facts hints, `composerMenu` and `toolCatalog` in `config/api.json` and `config/ui.json`
  say `domain.action` (or `domain`), never a rendered tool name.
- Keep the conformance test in `plugin/django/tests/test_agent_actions.py`:

  ```python
  from pathlib import Path
  from yeshuman.sdk.conformance import check_actions

  PACK_ROOT = Path(__file__).resolve().parents[3]

  def test_agent_actions_conform():
      assert check_actions(PACK_ROOT) == []
  ```

- Keep the terminology test in `plugin/django/tests/test_terminology.py`. It runs the platform's
  `scripts/check_terminology.py --root <pack>` against this pack's `terminology_allowlist.txt`.
  Rename a flagged name; add an allowlist line (`path :: name :: category :: reason`) only for a
  known, justified exception.

## Check

```bash
cd .platform/cli && uv run yeshuman test <handle> --pack
python3 .platform/scripts/check_terminology.py --root . --allowlist terminology_allowlist.txt
```

`check_actions` fails on: grammar or denylist words, a noun missing from `NOUNS`, untyped input or
result, context fields in inputs, DESTRUCTIVE without confirm, long descriptions or tool names in
them, missing labels, duplicate rendered names, rendered names in config, and any hand-built
`BaseTool` / `@tool` (legacy) not in the shrink-only baseline.
