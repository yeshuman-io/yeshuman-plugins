# Yes Human plugins

Cursor plugins for teams building on the Yes Human platform.

## `yeshuman-pack`

For agents working in a Yes Human **tenant pack** (a repo with `yeshuman.yaml` at its root):

| Piece | What it does |
|-------|--------------|
| Rule `platform-readonly` | `.platform/` is a read-only platform checkout; never commit from it. |
| Skill `yeshuman-pack-orientation` | The pack/platform split, install and run, and the pack-or-platform decision. |
| Skill `yeshuman-pack-feature` | Building through config and the Django / Labs plugin contracts, then verifying. |
| Skill `yeshuman-platform-request` | Raising a platform change as a `platform-request` issue (template in the pack's `.github/ISSUE_TEMPLATE/`), or a `## Platform request` PR-body section when issue creation fails; what to do when the platform PR lands. |
| Skill `yeshuman-platform-upgrade` | Catching the pack's `requires_product` pin up to the latest platform minor in its own PR (`contract_status.py`, reinstall, test, squash-merge to `staging`); staying pinned with `platform_pin:`; majors are never self-upgraded. |
| Skill `yeshuman-plan-to-make-a-plan` | Planning a Linear issue with the user (discovery, pack vs platform, where it lives) before any build. Slash command `/yeshuman-plan-to-make-a-plan`. |
| Skill `yeshuman-linear-evidence` | Posting evidence (screenshot, video, API or test output) and a Given/When/Then "How to verify" on the Linear issue and PR; includes `linear_evidence.py` for the no-MCP path. |

### Install

Cursor Dashboard → **Plugins & MCPs** → **Add Marketplace** → **Import from Repo** → `https://github.com/yeshuman-io/yeshuman-plugins`. Then set `yeshuman-pack` to **Default On** (or **Required**) for the team.

## Pack template

`templates/pack/` holds the files a pack needs to be a runnable Cursor Cloud workspace: `AGENTS.md`, `.cursor/install.sh` (clones the platform into `.platform/` with the `YESHUMAN_PLATFORM_TOKEN` secret), `.cursor/environment.json`, `.cursor/Dockerfile` (one `FROM` line, see below), `deploy/` (Railway Dockerfiles that clone the platform), `.dockerignore`, `.gitignore`, and `.github/ISSUE_TEMPLATE/platform-request.md`. `apply_pack_template.sh` also creates the `platform-request` and `agent-feedback` labels from `.github/labels.tsv` through `scripts/ensure_pack_labels.sh` when its `gh` login has Issues: write; otherwise it prints the command to run.

**Interim (until team marketplace Cloud attach works):** the template also copies `yeshuman-*` project skills into `.cursor/skills/` and `platform-readonly` into `.cursor/rules/`. Cloud Agents load those from the pack clone, so a Teams account is not required for this fallback. Canonical skill source remains `plugins/yeshuman-pack/`. Do not bake the plugin into `install.sh`, `Dockerfile`, or `environment.json`. Drop this copy once team marketplace Cloud attach is reliable.

```bash
scripts/apply_pack_template.sh <pack_dir>   # fills handle and ports from yeshuman.yaml
```

Optional `origin_url` in `yeshuman.yaml` (a plain `https://` URL) adds a sentence to `AGENTS.md` telling agents to open and review pull requests on Origin at that URL. Without it, nothing is added.

Cloud secrets for the pack's Cursor team: `YESHUMAN_PLATFORM_TOKEN` (read access to the platform repo), `OPENAI_API_KEY`, optional `YESHUMAN_PLATFORM_REF` (default `master`) and `YESHUMAN_SEED_DEPLOYMENT_USERS`.

## Cloud base image

`images/cloud-base/Dockerfile` is the Cloud VM toolchain (Ubuntu 24.04, Postgres 18 + pgvector, Node 22 + pnpm 9, uv + Python 3.13). No platform or pack code. `.github/workflows/cloud-base.yml` publishes it to `ghcr.io/yeshuman-io/cloud-base` on merges to `main` that touch it, or by hand (**Actions** → **cloud-base image** → **Run workflow**).

| Tag | Meaning |
|-----|---------|
| `:1` | Current toolchain; moves on non-breaking updates. Packs use this. |
| `:1.YYYYMMDD` | Immutable build, for rollback. |
| `:2` | Next breaking change (for example a new Postgres major); bump `MAJOR` in the workflow and move packs deliberately. |

Cursor picks up a moved tag on the next environment build.

## Contributing

This repo is public. It holds generic guidance only: no tenant names, credentials or deployment details. `scripts/check_no_client_names.sh` enforces the first of those against Yes Human's private fleet list.
