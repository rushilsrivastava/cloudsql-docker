#!/bin/bash
set -e

echo "Testing pg_cron configuration..."

# Check if postgresql.conf contains pg_cron settings
echo "Checking postgresql.conf..."
if grep -q "pg_cron configuration" "${PGDATA}/postgresql.conf"; then
    echo "✓ pg_cron configuration found in postgresql.conf"
else
    echo "✗ pg_cron configuration not found in postgresql.conf"
    exit 1
fi

# Check if shared_preload_libraries contains pg_cron
if grep -q "shared_preload_libraries = 'pg_cron'" "${PGDATA}/postgresql.conf"; then
    echo "✓ pg_cron is in shared_preload_libraries"
else
    echo "✗ pg_cron not found in shared_preload_libraries"
    exit 1
fi

echo "All checks passed!"
