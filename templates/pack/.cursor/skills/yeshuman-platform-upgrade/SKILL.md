---
name: yeshuman-platform-upgrade
description: Catch a Yes Human tenant pack up to the latest platform minor in its own PR — check the pin with contract_status.py, read the changelog rows and deprecations, raise requires_product / requiresProduct, reinstall, test, verify, squash-merge to staging and confirm the deploy. Also covers staying pinned on purpose and why majors are never self-upgraded. Use when yeshuman-pack-orientation reports the pack as behind or mismatch, before any feature work.
---

# Catch up with the platform

The platform's version is its **product contract** (`PRODUCT_CONTRACT_VERSION`, semver). A pack pins it twice: `requires_product` in its Django `PLUGIN` and `requiresProduct` in `plugin/labs/index.ts`. The floor of that range is the last minor the pack was tested on.

Minor versions are backward compatible, so a pack on `>=2.2,<3` already *runs* on 2.4: every install clones the tip of the platform branch. Catching up means proving that with tests and raising the floor so the pin says so. Merging also redeploys the pack's Railway `staging` onto the latest platform, which otherwise only happens on the pack's next merge.

## 1. Check

```bash
python3 .platform/scripts/pack_workspace/contract_status.py
```

| Status | Do |
|--------|----|
| `current` | Nothing. Go back to your task. |
| `behind` or `mismatch` | Catch up (below) **before** any feature work, unless the pack is pinned, a catch-up PR is already open, or your feature itself needs the newer version (then raise the floor in the feature PR, with a `## Platform pin` section in its body). |
| `incompatible` | The pin excludes this platform (a new major, or a floor above it). Stop: file an `agent-feedback` issue with the output. Never edit the cap yourself. |
| `missing` | A plugin side declares no pin. File `agent-feedback` and stop. |

**Skip catch-up** (and say so in your report) when:
- `yeshuman.yaml` has `platform_pin:`. The pack is held on purpose; leave it unless the user asks.
- An open PR titled `Platform catch-up: …` already exists (`gh pr list --search "Platform catch-up in:title"`). Another agent owns it. Do your task on top of current `staging`.
- The user says the client is near a release. Record a pin instead (section 4).

## 2. Catch up (its own PR)

A pure catch-up (nothing in your task needs the newer version) never rides in a feature PR. The exception: when the feature itself needs the newer contract, the feature PR raises the floor itself, with a `## Platform pin` section in its body saying what needs it (`yeshuman-pack-feature`, Before you start). Then there is no separate catch-up.

1. `git fetch origin staging && git checkout -b <prefix>/platform-catch-up-<X.Y> origin/staging` (cut from current `staging`).
2. Read what changed: the contract index at the top of `.platform/CHANGELOG.md` from your floor up to the latest, and every `### Deprecated` entry. Grep the pack for each deprecated name (`rg -n '<name>' plugin/`). If one is used, switch to the replacement in this PR only when it is a small, mechanical rename. Otherwise list it in the PR and leave the switch for a follow-up.
3. Bump both pins: `python3 .platform/scripts/pack_workspace/contract_status.py --write`. It writes `>=X.Y,<N+1` and re-checks, and the status must now be `current`.
4. Reinstall and run, on this head:
   - `bash .cursor/install.sh`
   - `bash .platform/scripts/pack_workspace/run.sh`
   - `cd .platform/cli && uv run yeshuman verify <handle>`
   - `cd .platform/cli && uv run yeshuman test <handle> --pack` (the pack's own tests)
   - `rg -i 'deprecat' .platform/api/logs/<handle>.log` (list any hits in the PR)
   - Open Labs on `labs_port` and log in. If the pack has Labs pages, open one.
5. Open the PR against `staging`, titled `Platform catch-up: require product X.Y`. The body gives the old and new pins, the changelog rows covered, the commands and their results, any deprecation hits, and the Railway preview link. There is no Linear issue and no user-visible change, so the evidence is the test output in the body.

## 3. Merge

A catch-up is the easiest self-merge there is: two pack files, two lines. Apply the bar in `yeshuman-pack-feature` (Merge) as usual. The Railway preview must be green on the head SHA, and nobody may have asked to hold. If this pack's PR environments deploy no services (Railway says "no services deployed" on every PR), say so in the PR; the local tests in step 2 then stand in for the preview. Squash-merge (`gh pr merge <n> --squash`, or the API with `merge_method=squash`). Then confirm the `staging` deploy is green and `uv run --with pyyaml deploy/smoke.py` passes against `staging`. If it is not, open a revert PR straight away and file `agent-feedback`.

Then rebase or restart your feature branch on the new `staging` and carry on.

## 4. When it fails, or the pack should wait

Do not bump. Do not patch around a platform break in the pack.

- **A minor broke the pack** (install, verify or the pack tests fail only after the bump or reinstall): that is a platform bug, because minors must be backward compatible. File `agent-feedback` with the failing command, the last lines of output and the platform commit (`git -C .platform log -1 --oneline`).
- **Stay pinned** (a failing catch-up, or a client near a release): add one line to `yeshuman.yaml`, `platform_pin: "<floor> — <reason> (<YYYY-MM-DD>)"`, in its own small PR. `contract_status.py` reports the pin and orientation stops asking. Remove the line in the catch-up PR that finally lands.

## Majors

A major (`3.0.0`) removes or changes pack-facing surface. Packs **never self-upgrade** across one: the `<N+1` cap is there to hold them. Yes Human runs majors as a staged rollout: a pilot pack first, then the rest, following the **Migration** list in the changelog, with timing set by Yes Human for clients near production. If `contract_status.py` says `incompatible` because the platform is a major ahead, stop and report it; do not raise the cap.
