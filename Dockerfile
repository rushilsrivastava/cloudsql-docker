ARG PG_VERSION=15
ARG POSTGIS_VERSION=3.5
FROM postgis/postgis:${PG_VERSION}-${POSTGIS_VERSION}

# Add PostgreSQL repository for pg_cron
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
    && curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null \
    && echo "deb http://apt.postgresql.org/pub/repos/apt/ $(. /etc/os-release && echo $VERSION_CODENAME)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update

# Install pg_cron
RUN apt-get install -y --no-install-recommends \
        postgresql-${PG_VERSION%%.*}-cron \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy initialization script
COPY init-pg-cron.sh /docker-entrypoint-initdb.d/

# Make the script executable
RUN chmod +x /docker-entrypoint-initdb.d/init-pg-cron.sh

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD pg_isready -U postgres || exit 1