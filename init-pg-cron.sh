#!/bin/bash
set -e

echo "Configuring pg_cron..."

# Use database from env or default to postgres
dbname=${POSTGRES_CRON_DB:-postgres}

# Create custom config file
customconf="${PGDATA}/custom-pg-cron.conf"
echo "# pg_cron configuration" > "$customconf"
echo "shared_preload_libraries = 'pg_cron'" >> "$customconf"
echo "cron.database_name = '$dbname'" >> "$customconf"
echo "cron.use_background_workers = on" >> "$customconf"
echo "max_worker_processes = 20" >> "$customconf"

# Set proper permissions
chown postgres:postgres "$customconf"

# Include custom config in main config
conf="${PGDATA}/postgresql.conf"
if ! grep -q "include = '$customconf'" "$conf"; then
    echo "include = '$customconf'" >> "$conf"
fi

echo "PostgreSQL configuration:"
cat "$customconf"

echo "Restarting PostgreSQL..."
pg_ctl -D "${PGDATA}" -m fast -w restart

echo "Creating pg_cron extension..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$dbname" <<-EOSQL
    -- Create extension
    CREATE EXTENSION IF NOT EXISTS pg_cron;

    -- Grant usage to postgres user
    GRANT USAGE ON SCHEMA cron TO postgres;
EOSQL

echo "pg_cron installation complete!"
