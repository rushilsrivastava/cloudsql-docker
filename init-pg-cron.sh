#!/bin/bash
set -e

# Enable pg_cron extension in shared_preload_libraries
sed -i "s/#shared_preload_libraries = ''/shared_preload_libraries = 'pg_cron'/g" ${PGDATA}/postgresql.conf

# Restart PostgreSQL to load the library
pg_ctl -D ${PGDATA} -m fast -w restart

# Now create the extension
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create the extension
    CREATE EXTENSION IF NOT EXISTS pg_cron;
EOSQL

# Configure pg_cron after extension is created
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Set the database where the pg_cron background worker will run
    SELECT cron.set_database('postgres');
EOSQL

# Final restart to ensure all settings are applied
pg_ctl -D ${PGDATA} -m fast -w restart
