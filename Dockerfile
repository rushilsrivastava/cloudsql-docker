ARG PG_VERSION=15
ARG POSTGIS_VERSION=3.5
ARG HLL_VERSION=2.18

# Build stage for HLL
FROM postgis/postgis:${PG_VERSION}-${POSTGIS_VERSION} AS builder

# Re-declare build args after FROM
ARG PG_VERSION
ARG POSTGIS_VERSION
ARG HLL_VERSION

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install -y \
    postgresql-server-dev-${PG_VERSION%%.*} \
    make \
    gcc \
    g++ \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN wget https://github.com/citusdata/postgresql-hll/archive/refs/tags/v${HLL_VERSION}.tar.gz -O postgresql-hll.tar.gz && \
    mkdir postgresql-hll && \
    tar xf ./postgresql-hll.tar.gz -C postgresql-hll --strip-components 1
WORKDIR /src/postgresql-hll
RUN make && make install

# Final stage
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

# Copy HLL extension files from builder
COPY --from=builder /usr/share/postgresql/${PG_VERSION%%.*}/extension/hll*.sql /usr/share/postgresql/${PG_VERSION%%.*}/extension/
COPY --from=builder /usr/share/postgresql/${PG_VERSION%%.*}/extension/hll.control /usr/share/postgresql/${PG_VERSION%%.*}/extension/
COPY --from=builder /usr/lib/postgresql/${PG_VERSION%%.*}/lib/hll.so /usr/lib/postgresql/${PG_VERSION%%.*}/lib/

# Configure shared preload libraries for both extensions
RUN echo "shared_preload_libraries = 'pg_cron,hll'" >> /usr/share/postgresql/postgresql.conf.sample

# Set default cron database
ENV POSTGRES_CRON_DB=postgres

# Copy initialization scripts
COPY init-pg-cron.sh /docker-entrypoint-initdb.d/00-init-pg-cron.sh

# Make the scripts executable
RUN chmod +x /docker-entrypoint-initdb.d/00-init-pg-cron.sh

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD pg_isready -U postgres || exit 1