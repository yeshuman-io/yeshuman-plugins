#!/bin/sh
# Railway pre-deploy for <handle>-api (deploy/api.railway.toml). A script, because Railway runs
# a Dockerfile service's commands in exec form, where `&&` is not a shell operator.
set -eu
cd /app
python manage.py migrate --noinput
python manage.py bootstrap_tenant
