# Cursor Cloud base image for Yes Human workspaces: toolchain only.
# Published as ghcr.io/yeshuman-io/cloud-base by .github/workflows/cloud-base.yml.
# No project code here; Cursor checks out the repo and .cursor/install.sh clones the platform.
FROM ubuntu:24.04

LABEL org.opencontainers.image.source=https://github.com/yeshuman-io/yeshuman-plugins
LABEL org.opencontainers.image.description="Cursor Cloud toolchain: Postgres 18 + pgvector, Node 22 + pnpm 9, uv + Python 3.13"
LABEL org.opencontainers.image.licenses=MIT

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gnupg \
        lsb-release \
        sudo \
        locales \
        build-essential \
        pkg-config \
        python3-dev \
        libpq-dev \
        wget \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# PostgreSQL 18 + pgvector (PGDG). Ubuntu 24.04 ships 16 by default.
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        | gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-18 \
        postgresql-contrib-18 \
        postgresql-client-18 \
        postgresql-18-pgvector \
    && rm -rf /var/lib/apt/lists/*

# yeshuman CLI connects on host=localhost (TCP). Trust is fine on an isolated Cloud VM.
RUN if [ -f /etc/postgresql/18/main/pg_hba.conf ]; then \
        sed -i 's/scram-sha-256/trust/g' /etc/postgresql/18/main/pg_hba.conf ; \
    fi \
    && (pg_lsclusters | grep -q '18.*main' || pg_createcluster 18 main)

# Node 22 + pnpm 9 (Labs / jobs)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && corepack enable \
    && corepack prepare pnpm@9.0.0 --activate \
    && rm -rf /var/lib/apt/lists/*

# Non-root Cloud Agent user
RUN id -u ubuntu >/dev/null 2>&1 || useradd -m -s /bin/bash ubuntu \
    && usermod -aG sudo ubuntu \
    && echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu

USER ubuntu
ENV HOME=/home/ubuntu
ENV PATH="/home/ubuntu/.local/bin:${PATH}"
WORKDIR /home/ubuntu

# Python 3.13 via uv (API / CLI require >=3.13,<3.14)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && /home/ubuntu/.local/bin/uv python install 3.13
