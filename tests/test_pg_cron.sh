#!/bin/bash
set -e

# Function to run SQL commands
run_sql() {
    docker exec postgres-test psql -U postgres -d postgres -t -A -c "$1"
}

# Wait for PostgreSQL to be ready
wait_for_postgres() {
    echo "Waiting for PostgreSQL to be ready..."
    for i in {1..30}; do
        if docker exec postgres-test pg_isready -U postgres > /dev/null 2>&1; then
            echo "PostgreSQL is ready!"
            return 0
        fi
        sleep 1
    done
    echo "PostgreSQL did not become ready in time"
    return 1
}

echo "Starting PostgreSQL container..."
docker run -d --name postgres-test \
    -e POSTGRES_PASSWORD=postgres \
    postgis-cloudsql:test

# Wait for PostgreSQL to be ready
wait_for_postgres

echo "Testing pg_cron installation..."

# Verify configuration
echo "Checking PostgreSQL configuration..."
run_sql "SHOW shared_preload_libraries;"
run_sql "SHOW cron.database_name;"
run_sql "SHOW cron.use_background_workers;"
run_sql "SHOW max_worker_processes;"

# Creating extension pg_cron
echo "Installing pg_cron extension..."
run_sql "CREATE EXTENSION IF NOT EXISTS pg_cron;"

# Verify extension
echo "Checking pg_cron extension..."
if ! run_sql "SELECT extname, extversion FROM pg_extension WHERE extname = 'pg_cron';" | grep -q "pg_cron"; then
    echo " pg_cron extension is not installed"
    exit 1
fi
echo " pg_cron extension is installed"

# Verify cron schema and permissions
echo "Checking cron schema..."
if ! run_sql "\dn" | grep -q "cron"; then
    echo " cron schema does not exist"
    exit 1
fi
echo " cron schema exists"

echo "Testing pg_cron functionality..."
# Create a test table
run_sql "CREATE TABLE IF NOT EXISTS test_cron (id serial primary key, created_at timestamp default current_timestamp);"

# Schedule a job
echo "Scheduling test job..."
run_sql "SELECT cron.schedule('test-job', '* * * * *', 'INSERT INTO test_cron DEFAULT VALUES');"

# Verify job creation
echo "Verifying job creation..."
if ! run_sql "SELECT jobname, schedule, command FROM cron.job WHERE jobname = 'test-job';" | grep -q "test-job"; then
    echo " Failed to create cron job"
    echo "Current jobs in cron.job:"
    run_sql "SELECT * FROM cron.job;"
    exit 1
fi
echo " Job created successfully"

# Wait for job execution
echo "Waiting for job execution (65 seconds)..."
sleep 65

# Check job execution
echo "Checking job execution..."
COUNT=$(run_sql "SELECT COUNT(*) FROM test_cron;" | tr -d ' ')
if [ "$COUNT" -eq 0 ]; then
    echo " Job did not execute"
    echo "Checking job run details:"
    run_sql "SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 5;"
    exit 1
else
    echo " Job executed successfully ($COUNT records created)"
    echo "Job run details:"
    run_sql "SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 1;"
fi

# Cleanup
echo "Cleaning up..."
docker stop postgres-test
docker rm postgres-test

echo "All tests passed! "
