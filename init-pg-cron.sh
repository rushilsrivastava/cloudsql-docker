#!/bin/bash
set -e

echo "Configuring pg_cron..."

# Always use postgres as the database for pg_cron background worker
# This is required by pg_cron, but you can schedule jobs in other databases using cron.schedule_in_database()
echo "Setting up pg_cron to run in the 'postgres' database"

# Wait for PostgreSQL config directory to be ready
while [ ! -d "${PGDATA}" ]; do
    echo "Waiting for PGDATA directory to be ready..."
    sleep 1
done

conf="${PGDATA}/postgresql.conf"
echo "Configuring pg_cron in: ${conf}"

# Function to add or update a PostgreSQL configuration parameter
update_conf() {
    local param="$1"
    local value="$2"
    local search_pattern="^#*\s*${param}\s*=.*"
    
    if grep -q "$search_pattern" "$conf"; then
        # Parameter exists (commented or uncommented), update it
        sed -i "s@${search_pattern}@${param} = ${value}@" "$conf"
        echo "Updated ${param} = ${value}"
    else
        # Parameter doesn't exist, add it in the appropriate section
        echo "" >> "$conf"
        echo "# Added by pg_cron configuration" >> "$conf"
        echo "${param} = ${value}" >> "$conf"
        echo "Added ${param} = ${value}"
    fi
}

# Check if pg_cron is already configured
if ! grep -q "pg_cron configuration" "$conf" 2>/dev/null; then
    echo "Adding pg_cron configuration to postgresql.conf..."
    
    # Backup the original file
    cp "$conf" "${conf}.backup"
    echo "Created backup at ${conf}.backup"
    
    # Update the configuration parameters
    update_conf "shared_preload_libraries" "'pg_cron'"
    update_conf "cron.database_name" "'postgres'"  # This must be 'postgres'
    update_conf "cron.use_background_workers" "on"
    update_conf "max_worker_processes" "20"
    update_conf "cron.host" "''"
    
    echo "Configuration added. New pg_cron related settings:"
    grep -i "cron\|shared_preload" "$conf"
    
    echo "PostgreSQL configuration updated for pg_cron."
    echo ""
    echo "IMPORTANT: pg_cron background worker must run in the 'postgres' database,"
    echo "but you can schedule jobs in other databases using cron.schedule_in_database()."
    echo ""
    echo "Example for scheduling in another database:"
    echo "SELECT cron.schedule_in_database('job_name', '*/5 * * * *', 'SELECT 1', 'other_database');"
else
    echo "pg_cron configuration already exists in postgresql.conf"
fi

echo "Configuration complete. Full postgresql.conf contents:"
cat "$conf"
