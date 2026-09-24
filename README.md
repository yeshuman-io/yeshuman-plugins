# Yes Human plugins

Cursor plugins for teams building on the Yes Human platform.

## `yeshuman-pack`

For agents working in a Yes Human **tenant pack** (a repo with `yeshuman.yaml` at its root):

| Piece | What it does |
|-------|--------------|
| Rule `platform-readonly` | `.platform/` is a read-only platform checkout; never commit from it. |
| Skill `yh-pack-orientation` | The pack/platform split, install and run, and the pack-or-platform decision. |
| Skill `yh-pack-feature` | Building through config and the Django / Labs plugin contracts, then verifying. |
| Skill `yh-platform-request` | Raising a platform change as a `platform-request` issue with a prototype diff. |

### Install

Cursor Dashboard → **Plugins & MCPs** → **Add Marketplace** → **Import from Repo** → `https://github.com/yeshuman-io/yeshuman-plugins`. Then set `yeshuman-pack` to **Default On** (or **Required**) for the team.

## Pack template

`templates/pack/` holds the few files a pack needs to be a runnable Cursor Cloud workspace: `AGENTS.md`, `.cursor/install.sh` (clones the platform into `.platform/` with the `YESHUMAN_PLATFORM_TOKEN` secret), `.cursor/environment.json`, `.cursor/Dockerfile`, and `.gitignore`.

```bash
scripts/apply_pack_template.sh <pack_dir>   # fills handle and ports from yeshuman.yaml
```

Cloud secrets for the pack's Cursor team: `YESHUMAN_PLATFORM_TOKEN` (read access to the platform repo), `OPENAI_API_KEY`, optional `YESHUMAN_PLATFORM_REF` (default `master`) and `YESHUMAN_SEED_DEPLOYMENT_USERS`.

## Contributing

This repo is public. It holds generic guidance only: no tenant names, credentials or deployment details. `scripts/check_no_client_names.sh` enforces the first of those against Yes Human's private fleet list.
