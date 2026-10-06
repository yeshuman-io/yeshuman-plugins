# Railway <handle>-api, built from this pack: platform api/ at /app, this pack at /app/tenant-pack.
FROM python:3.13-slim-bookworm

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    git openssh-client ca-certificates \
    libpango-1.0-0 libpangocairo-1.0-0 libglib2.0-0 libgdk-pixbuf-2.0-0 libffi-dev \
    shared-mime-info fonts-dejavu-core \
  && rm -rf /var/lib/apt/lists/*

ARG YESHUMAN_PLATFORM_REPO=yeshuman-io/yeshuman
ARG YESHUMAN_PLATFORM_REF=master
ARG YESHUMAN_PLATFORM_SSH_KEY=""
ARG YESHUMAN_PLATFORM_TOKEN=""
# Changes on every pack commit, so each pack build re-clones the platform ref.
ARG RAILWAY_GIT_COMMIT_SHA=""

COPY deploy/clone-platform.sh /tmp/clone-platform.sh
RUN echo "pack ${RAILWAY_GIT_COMMIT_SHA}" \
  && sh /tmp/clone-platform.sh /tmp/platform \
  && mkdir -p /app \
  && cp -a /tmp/platform/api/. /app/ \
  && rm -rf /tmp/platform /tmp/clone-platform.sh

WORKDIR /app
ENV UV_PROJECT_ENVIRONMENT=/opt/venv \
  PATH=/opt/venv/bin:$PATH \
  PYTHONPATH=/app \
  DJANGO_SETTINGS_MODULE=yeshuman.settings \
  TENANT_ROOT=/app/tenant-pack
RUN pip install --no-cache-dir "uv==$(sed -n 's/^uv //p' .tool-versions)" \
  && uv sync --no-dev --frozen

COPY . /app/tenant-pack

# Fallback for a service whose pre-deploy only migrates: bootstrap a never-bootstrapped
# database once. A failure is logged and the server still starts.
CMD ["sh", "-c", "python manage.py bootstrap_tenant --if-needed || echo 'bootstrap_tenant --if-needed failed, see above'; exec daphne -b 0.0.0.0 -p ${PORT:-8000} yeshuman.asgi:application"]
