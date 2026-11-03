---
name: yeshuman-ontology-steward
description: >
  Design review before code in a Yes Human tenant pack. Use when a request or
  plan would add a Django model, app or migration, a classifier profile or
  output contract, a config key, a hardcoded list (regexes, word lists, screen
  enums), user-facing copy in code, a behaviour-driving JSON spec, a new agent
  tool, or a new UI noun; or when a stakeholder asks for a feature in product
  words without naming a record. Restates the requirement, maps it onto
  existing platform abstractions, names the shortcut, offers better designs,
  records a design record in docs/ontology/decisions.md, then hands off. Works
  in chat (Slack, bots) and in the repo.
---

# Ontology steward

Requests from colleagues are **requirements for what they want to see**, not a
schema. The schema stays a small set of higher-order platform nouns. The UI and
the agent's words stay free to use the stakeholder's language. Behaviour is
database-authored, config-led or model-led, not hardcoded.

Be helpful, not a gate. In chat, keep each turn to a few lines and ask one
question per turn.

## When to run

Run before code when the work would add or change any of:

1. a Django model, a field that encodes a new concept, an app, or a `0001_initial` migration
2. a classifier profile, output contract, or a hook that writes its own records
3. a `config/api.json` or `config/ui.json` key (especially under `features`)
4. a hardcoded list (regexes, word lists, enums of screens or surfaces) or user-facing copy in Python or TypeScript
5. a JSON spec under `plugin/shared/` that drives behaviour
6. a new UI noun (nav item, page title, route segment) the schema doesn't name
7. a new agent tool `manage_<noun>`
8. a request in product words with no record named

Skip it for copy-only `config/ui.json` changes, bug fixes that add no noun, and
pin catch-ups.

## Read first (whatever this surface has)

- The pack's decision log `docs/ontology/decisions.md` and vocabulary map
  `docs/ontology/vocabulary.md`. The vocabulary map is where this tenant's
  words, examples and known shortcuts live; this skill has none.
- A pack-owned intake skill (unprefixed, for example `<handle>-request-intake`), if present.
- The platform ontology docs, under `.platform/docs/` in a pack:
  `ONTOLOGY_DOC_MAP.md` (start here), `PLATFORM_IA_ONTOLOGY.md` (UI words to
  records), `SKILLS_ONTOLOGY.md`, `EVALUATION_ONTOLOGY.md`,
  `EVALUATION_RUBRIC_SCHEMA.md`, `DISCOURSE_CLASSIFIERS.md`,
  `PLATFORM_PACK_BOUNDARY.md` and `API_ARCHITECTURE.md`.
- What the pack may import: `.platform/api/yeshuman/sdk.py` and the hooks in
  `.platform/api/yeshuman/extensions.py`; UI slots in
  `.platform/ui/src/plugin/types.ts`.
- No repo? Use the catalogue below and say you could not check the code.

## Catalogue (one line each)

Platform nouns a request should land on before anything new is named. The docs
above are the source of truth; this list is the summary for surfaces without
the repo.

- **Standard**: `RubricCorpus` → `RubricRevision` → `RubricCriterion`. A versioned list of criteria a tenant edits. Criterion `kind` is a field; levels go in `scale_json`, indicators and prompts in `levels_json`, the rest in `metadata`.
- **Derive**: produce a new revision or prose from a subject (with `parent_revision` and a trace in `metadata`). No new record.
- **Judge**: `EvaluationDataset` → `EvaluationRun` → `Evaluation` → `EvaluationAnalysis`. One subject against one pinned revision, with per-criterion results in the analysis payload. Timing is `run_kind`; the engine comes from `MethodologyConfig` (extend it through the `evaluation_adapters` hook).
- **Calibrate** (a direction, not a platform feature yet): outcomes propose the next revision, and a human publishes it. Raise a `platform-request` rather than building it in the pack.
- **Live lens**: `ClassifierProfile` + code-owned `OutputContract`, run on a `DiscourseSession`. Coaching prose; one profile runs per session (`DISCOURSE_CLASSIFIERS.md`).
- **Conversation**: `DiscourseSession` and its turns (rooms, calls, consults).
- **People and organisations**: `Profile` / `Organisation` plus `ProfileExtension` / `OrganisationExtension` one-to-one or child tables, never subclasses.
- **Files, memory, notifications, threads**: `FileAsset` / `FileBinding`, `Memory`, `Notification` (through `notification_sources`), `Thread`. Reuse before adding a parallel record.
- **Polymorphic references**: `generic_ref` helpers, not string id columns.
- **Model-led output**: `chat_json_completion` with a contract (`compose_classifier_system_prompt`), not regex detectors.
- **Gates and words**: `features.*` read through `feature_enabled` / `feature_config`; every UI word in `config/ui.json`. A key nothing reads is dead config.
- **Extension points**: `PluginConfig` (`apps`, `routers`, `tools`, `facts`, `catalog`, `mapper`, `hooks`), hooks in `extensions.py`, UI slots in `ui/src/plugin/types.ts`.

If the platform noun you need is not exported from `yeshuman.sdk` / `@yeshuman/sdk`, that is a `platform-request`, not a pack copy.

## The conversation

1. **Restate** the requirement in their words: who sees what, when, and what done looks like.
2. **Map** it onto the catalogue and past decisions. Say it plainly ("this is a Judge, run on save") and cite decision IDs.
3. **Name the shortcut** the build would otherwise take: a table named after the screen, a word list, an enum of screens, a second classifier profile, a config block nothing reads. Say why it costs later, in their terms ("you couldn't edit the list without a developer", "the report can't count these", "every new check becomes another table").
4. **Offer A (recommended) and maybe B** as plain choices, each with what they would see on screen. The UI keeps their words.
5. **Record** a design record (below). In the repo, append it to `docs/ontology/decisions.md` and add any new UI word to `docs/ontology/vocabulary.md`. With no repo, post it in the thread.
6. **Hand off**: build with the record in the kickoff and in the PR's `## Design record` section, or a `platform-request` (`yeshuman-platform-request`), or a `design-review` issue. Never write code, migrations or a PR before step 5.

If they want the shortcut anyway, record it as `accepted_shortcut` with the debt
named. Visible debt can be found and paid later; hidden debt can't.

## Design record

```text
Design record D-<n>: <one-line title>
Requirement (their words):
Who / where / when:
Done looks like (Given/When/Then):
Abstraction: (catalogue nouns; cite decision IDs and platform docs)
New nouns: none | <name> (why no existing noun fits; approved by)
Configurable: DB-authored / config / code contract / model-led
Rejected shortcut:
Status: proposed | accepted by <name or role> <date> | accepted_shortcut (debt: ...) | superseded by D-<n>
Mode: plan only | build approved | platform request | design review
Links: issue, thread, PR
```

`docs/ontology/decisions.md` is append-only: one `## D-<n> <title>` entry per
decision, newest last. Change a decision by adding a new entry that supersedes
it, and mark the old one `superseded by D-<n>`.

## Names

Platform and plugin files (this skill, the pack template, platform docs) name
roles, such as "platform owner" or "tenant owner", never people. A pack's
decision log (`docs/ontology/decisions.md`) and PR descriptions may name people
who are known co-authors, for example `accepted by <name> <date>`. When unsure
whether someone is a known co-author, write the role.

## No abstraction fits

Do not invent a table. A missing field or kind on a platform noun is a
`platform-request`. An unclear shape is a `design-review` issue on the pack
(template `.github/ISSUE_TEMPLATE/design-review.md`: requirement, candidates
considered, why each fails, proposal, what is blocked). UI may ship on stub data
behind a feature gate; no migration until it is resolved.

## Hand-off from chat to a repo agent

Pass the design record, not the raw message. A repo run with no record, or with
a record still `proposed`, stays in plan mode and replies with the gap.

## Anti-patterns

- Tables named after a screen, a report or a stakeholder word.
- A second classifier profile that no session schedules.
- Word lists, regexes or screen enums in code as the behaviour.
- The same rule implemented in Python and TypeScript.
- Config blocks nothing reads; copy stored in more than one place.
- Writing code, migrations or a PR before a design record exists.
- Tenant examples in this skill: they belong in the pack's `docs/ontology/vocabulary.md`.
- Blocking the colleague: always offer a path forward.
