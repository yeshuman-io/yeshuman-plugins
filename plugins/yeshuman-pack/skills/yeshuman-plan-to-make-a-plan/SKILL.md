---
name: yeshuman-plan-to-make-a-plan
description: >
  Plans Linear work with the user before any build: discovery questions, pack
  vs platform, where the change lives, then a real plan in chat. Use when
  Linear issues are scant or empty, when grooming Backlog/Todo, when asked to
  plan-to-make-a-plan or “plan this”, when picking an issue, or until the user
  explicitly asks to implement. Do not invent a spec or dump Goal/Scope into
  Linear. Slash command: /yeshuman-plan-to-make-a-plan.
---

# Plan to make a plan

Work **with** the user. Discovery first, then a plan you both own. Stay in this
skill until the user **explicitly** asks to implement (or open a PR). “Pick one to
work on” means **plan** that issue, not build it.

## Scant Linear issues

Many pack Linear issues have empty or thin bodies. That is the usual
starting point, not a reason to skip this skill or to fill Linear for them.

When grooming, “plan this”, or picking work, **use this skill first** to flesh
out *what they need to solve* with the user: discovery questions, pack vs
platform, where the change would live. Do not invent a spec. Do not dump
Goal / Scope / Out of scope into Linear to make the ticket look complete.

## Where this skill lives

This is a Yes Human skill, managed in `yeshuman-plugins` and copied into each
pack's `.cursor/skills/` on template refresh. Do not edit the pack copy; raise
a skill request instead. Its spirit matches the platform's monorepo
`plan-to-make-a-plan` (find → explore → then Plan mode), tailored to Linear on
a pack and the pack/platform split. Read the platform copy under
`.platform/.cursor/skills/` as reference only; do not copy it into the pack.

## Cite Linear in plain language

Always cite issues as **ID + one-line summary** so the user does not need to open Linear:

`ABC-123 — Candidate shortlist: seedable test path for saved jobs`

Not the ID alone. Not a stack of GitHub-style checklists unless they asked.

## Linear status meaning (default; follow the team's own if it differs)

| Status | Meaning | Agent does |
|--------|---------|------------|
| **Triage** | Not even a backlog item yet | Help classify; do not plan as if it is ready |
| **Backlog** | Discovery still needed | Plan in chat; **do not treat as ready to build** |
| **Todo** | Team knows enough to execute | Still plan-only until they say implement |
| **In Progress** / **In Review** / **Done** | Execution or later | Do not start coding because of these names |

Move **Backlog → Todo** only when discovery is honestly done (pack vs platform
settled, enough “what/where” to execute). Never invent that move. Do not set
**In Progress** from this skill.

## Linear text stays light

Collaborative planning happens **in chat** (and Cursor Plan mode when ready).

Write to Linear **only** what the user wants there. Default: a short title, a
couple of sentences or bullets they approved, links/relations they asked for.

**Do not** add:

- Estimates, story points, or t-shirt sizes
- A bulky Goal / Scope / Out of scope / Size (or similar) template
- A finished spec dumped from chat into the issue body

If an issue already has that bulky template, do not grow it. Offer to slim it
in chat; change Linear only if they want that.

## Workflow (find → explore → plan)

### 1. Find

Read the Linear issue (and related issues), even when the body is empty. Then
locate the work in **this** repo and the read-only platform checkout:

- Pack: `yeshuman.yaml`, `config/`, `plugin/`, `seeds/`
- Platform (read-only): `.platform/` — similar features, slots, existing
  behaviour. Use `yeshuman-pack-orientation` for the split.

Ask which Linear issue if the request is vague. Cover nearby code and prior
art before proposing a plan.

### 2. Explore (questions, not a lecture)

Short questions. Skip buckets they mark out of scope. Spikes in conversation
or read-only greps are OK; do not implement.

**Approach** — extend an existing flow vs new surface? Constraints (must-not-break, dependencies, launch vs later)?

**Pack vs platform (always when shared code or new capability might be involved)**

- Pack-only: config, theme, seeds, tenant plugin using existing slots → later
  `yeshuman-pack-feature`.
- Needs a new extension point or shared behaviour → later
  `yeshuman-platform-request`. Do not edit `.platform/` for real.
- Both: say which part is pack now and what waits on Yes Human.

**Where it lives** — config vs `plugin/django` vs `plugin/labs` vs platform
module. Prefer established patterns over a parallel style.

**Labs / UI** — which surfaces? Converge on an existing pattern or
deliberately replace? Deep product UX (who, journey, states) can wait for
platform `ui-ux-application-planning` when that skill is in context.

**Agent path** — tools, streaming, cache, artifacts, if the feature is
agent-interactive.

**API / server** — routes, models, jobs, permissions, data contracts.

**Tenant config** — `config/api.json`, `config/ui.json`, flags, seeds; local
vs Railway staging vs production.

### 3. Then a real plan (still not build)

When discovery is enough, write the plan **in chat** (recommend Cursor **Plan
mode** for a larger slice). The plan should name:

- The issue as `ABC-123 — summary`
- Pack vs platform and file/module targets
- Open questions that would block Todo
- What would be in Linear if they want a light update
- Explicit next step: stay planning, move to Todo, or (only if they asked)
  implement

Do not start implementation, tests-as-delivery, or a feature PR from this
skill.

## Anti-patterns

- Treating **Backlog** as a ready queue
- Filling empty Linear bodies with a spec the two of you have not discussed
- Adding estimates or size labels “for completeness”
- Editing `.platform/`, `.cursor/install.sh`, `.cursor/environment.json`, or
  `.cursor/Dockerfile`
- Editing any `yeshuman-*` skill in the pack, including this one
- Skipping the tenant-vs-shared / pack-vs-platform question
- Jumping to code when they said plan, pick, groom, or discover
