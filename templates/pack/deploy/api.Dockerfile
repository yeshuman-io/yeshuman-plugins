# Railway <handle>-api, built from this pack: platform api/ at /app, this pack at /app/tenant-pack.

# Stage 1: the screen map (platform screens + this pack's plugin/ui/screens.ts) is a build
# output, not committed (platform docs/SCREEN_MAP.md). The manifests import types only, so
# tsx alone runs the platform's generator; no pnpm install.
FROM node:22-bookworm-slim AS screen-map
RUN apt-get update \
  && apt-get install -y --no-install-recommends git openssh-client ca-certificates \
  && rm -rf /var/lib/apt/lists/*
ARG YESHUMAN_PLATFORM_REPO=yeshuman-io/yeshuman
ARG YESHUMAN_PLATFORM_REF=""
ARG YESHUMAN_PLATFORM_SSH_KEY=""
ARG YESHUMAN_PLATFORM_TOKEN=""
ARG RAILWAY_GIT_COMMIT_SHA=""
COPY deploy/clone-platform.sh deploy/platform-ref* /tmp/
RUN echo "pack ${RAILWAY_GIT_COMMIT_SHA}" \
  && sh /tmp/clone-platform.sh /tmp/platform /tmp/platform-ref
COPY . /pack
RUN mkdir -p /pack/config \
  && if [ -f /pack/plugin/ui/screens.ts ]; then \
       cd /tmp/platform/ui \
       && TENANT_ROOT=/pack npx --yes tsx@4.21.0 --tsconfig tsconfig.app.json scripts/build-screen-map.ts; \
     fi

# Stage 2: the API.
FROM python:3.13-slim-bookworm

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    git openssh-client ca-certificates \
    libpango-1.0-0 libpangocairo-1.0-0 libglib2.0-0 libgdk-pixbuf-2.0-0 libffi-dev \
    shared-mime-info fonts-dejavu-core \
  && rm -rf /var/lib/apt/lists/*

ARG YESHUMAN_PLATFORM_REPO=yeshuman-io/yeshuman
# Empty unless the service sets it (staging: "staging"); then deploy/platform-ref decides.
ARG YESHUMAN_PLATFORM_REF=""
ARG YESHUMAN_PLATFORM_SSH_KEY=""
ARG YESHUMAN_PLATFORM_TOKEN=""
# Changes on every pack commit, so each pack build re-clones the platform ref.
ARG RAILWAY_GIT_COMMIT_SHA=""

COPY deploy/clone-platform.sh deploy/platform-ref* /tmp/
RUN echo "pack ${RAILWAY_GIT_COMMIT_SHA}" \
  && sh /tmp/clone-platform.sh /tmp/platform /tmp/platform-ref \
  && mkdir -p /app \
  && cp -a /tmp/platform/api/. /app/ \
  && rm -rf /tmp/platform /tmp/clone-platform.sh /tmp/platform-ref

WORKDIR /app
ENV UV_PROJECT_ENVIRONMENT=/opt/venv \
  PATH=/opt/venv/bin:$PATH \
  PYTHONPATH=/app \
  DJANGO_SETTINGS_MODULE=yeshuman.settings \
  TENANT_ROOT=/app/tenant-pack
RUN pip install --no-cache-dir "uv==$(sed -n 's/^uv //p' .tool-versions)" \
  && uv sync --no-dev --frozen

COPY . /app/tenant-pack
# Empty when the pack has no screens.ts; the API then reads the platform's own map.
COPY --from=screen-map /pack/config/ /app/tenant-pack/config/

CMD ["sh", "-c", "daphne -b 0.0.0.0 -p ${PORT:-8000} yeshuman.asgi:application"]
