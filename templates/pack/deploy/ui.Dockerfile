# Railway <handle>-ui, built from this pack: platform labs/ at /app, this pack at /app/tenant-pack.
FROM node:22-bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends git openssh-client ca-certificates \
  && rm -rf /var/lib/apt/lists/*
RUN corepack enable

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
  && cp -a /tmp/platform/labs/. /app/ \
  && rm -rf /tmp/platform /tmp/clone-platform.sh

WORKDIR /app
ENV TENANT_ROOT=/app/tenant-pack
RUN pnpm install --frozen-lockfile

COPY . /app/tenant-pack

# Vite inlines these at build time; redeploy after changing them.
ARG VITE_CLIENT_CONFIG
ARG VITE_API_URL
ARG VITE_PUBLIC_JOBS_BOARD_URL
ARG VITE_PLATFORM_SIM_UI_ENABLED
ARG VITE_DEBUG_SSE
# Railway passes only declared ARGs into a build. On a PR environment Labs rewrites VITE_API_URL
# to this environment's own API (labs/src/lib/railway-preview-api.ts).
ARG RAILWAY_ENVIRONMENT_NAME
ARG RAILWAY_SERVICE___HANDLE_ENV___API_URL
RUN pnpm build

ENV NODE_ENV=production
CMD ["sh", "-c", "npm run preview -- --host 0.0.0.0 --port ${PORT:-4173}"]
