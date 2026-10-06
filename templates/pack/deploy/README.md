# deploy/ (managed by Yes Human)

Railway builds this pack's services from these files. Do not edit them in a pack PR; file an `agent-feedback` issue instead.

| Service | Railway config file path | Builds |
|---------|--------------------------|--------|
| `<handle>-api` | `deploy/api.railway.toml` | `deploy/api.Dockerfile`; pre-deploy `migrate` then `bootstrap_tenant` |
| `<handle>-ui` | `deploy/ui.railway.toml` | `deploy/ui.Dockerfile` |
| `talentco-jobs` (TalentCo only) | `jobs/railway.toml` | `jobs/Dockerfile` |

Railway reads only a root `railway.toml` unless a service's **Config file path** is set, so each service needs that setting pointing at the file above. The pre-deploy is `sh /app/tenant-pack/deploy/predeploy.sh` (migrate, then `bootstrap_tenant`). It is a script because Railway runs a Dockerfile service's commands in exec form: the earlier `python manage.py migrate && python manage.py bootstrap_tenant` string only ever migrated, so no staging was seeded. `GET /api/health` → `bootstrapped` shows whether `bootstrap_tenant` has run.

## Seeding by environment

`bootstrap_tenant` reads `RAILWAY_ENVIRONMENT_NAME`. **production** never gets `seeds/demo.yaml` users (their passwords are committed). **staging** and PR environments get them, with their yaml passwords reset on each deploy. `SEED_DEPLOYMENT_USERS` is optional on Railway. Accounts that must exist in production go in `SEED_DEPLOYMENT_USERS` in the dashboard, never in `seeds/demo.yaml`. Full table: platform `docs/TENANT_REPOS.md` (Railway bootstrap).

## Reference variables

On `staging`, and on whichever environment PR environments copy, use `${{…}}` references so each environment talks to its own services:

- api: `DATABASE_URL=${{<handle>-db.DATABASE_URL}}`, `REDIS_URL=${{<handle>-redis.REDIS_URL}}`, `ALLOWED_HOSTS` with `${{RAILWAY_PUBLIC_DOMAIN}}`, `CORS_ALLOWED_ORIGINS` and `FRONTEND_*` bases with `https://${{<handle>-ui.RAILWAY_PUBLIC_DOMAIN}}`.
- ui: `VITE_API_URL=https://${{<handle>-api.RAILWAY_PUBLIC_DOMAIN}}`, `VITE_ALLOWED_HOSTS` with `${{RAILWAY_PUBLIC_DOMAIN}}`.
- jobs: `PUBLIC_JOBS_API_ORIGIN=https://${{talentco-api.RAILWAY_PUBLIC_DOMAIN}}`.

Production keeps branded hosts, and adds them alongside the references elsewhere. PR builds also rewrite the API URL to the PR environment's own API (`RAILWAY_SERVICE_<HANDLE>_API_URL`), which is why `ui.Dockerfile` declares those `ARG`s. Full convention: platform `docs/RAILWAY.md` (Reference-variable convention).

## Smoke check

```bash
uv run --with pyyaml deploy/smoke.py --api https://<handle>-api-staging.up.railway.app \
  --labs https://<handle>-ui-staging.up.railway.app
```

This checks health, `bootstrapped`, Labs, and one demo login. TalentCo adds `--record /api/public/opportunities`. Use the PR environment's URLs from the Railway PR comment for a preview.
