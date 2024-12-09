#!/bin/bash
set -e

# First, add pg_cron to shared_preload_libraries
echo "shared_preload_libraries = 'pg_cron'" >> ${PGDATA}/postgresql.conf

# Restart PostgreSQL to load the library
pg_ctl -D ${PGDATA} -m fast -w restart

# Now create the extension and configure it
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- First create the extension
    CREATE EXTENSION IF NOT EXISTS pg_cron;
    
    -- Now we can safely configure it
    ALTER SYSTEM SET cron.database_name = 'postgres';
    SELECT pg_reload_conf();
EOSQL

# Final restart to ensure all settings are applied
pg_ctl -D ${PGDATA} -m fast -w restart
