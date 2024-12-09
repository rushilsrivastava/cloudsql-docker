#!/bin/bash
set -e

# Function to run SQL commands
run_sql() {
    docker exec postgres-test psql -U postgres -c "$1"
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
# Check if pg_cron extension exists
if run_sql "SELECT * FROM pg_extension WHERE extname = 'pg_cron';" | grep -q "pg_cron"; then
    echo "✅ pg_cron extension is installed"
else
    echo "❌ pg_cron extension is not installed"
    exit 1
fi

echo "Testing pg_cron functionality..."
# Create a test table
run_sql "CREATE TABLE IF NOT EXISTS test_cron (id serial primary key, created_at timestamp default current_timestamp);"

# Schedule a job
run_sql "SELECT cron.schedule('test-job', '* * * * *', 'INSERT INTO test_cron DEFAULT VALUES;');"

# Check if job was created
if run_sql "SELECT * FROM cron.job WHERE jobname = 'test-job';" | grep -q "test-job"; then
    echo "✅ Cron job was created successfully"
else
    echo "❌ Failed to create cron job"
    exit 1
fi

# Wait for a minute to let the job run
echo "Waiting for cron job to execute..."
sleep 65

# Check if job executed
if run_sql "SELECT COUNT(*) FROM test_cron;" | grep -q "0"; then
    echo "❌ Cron job did not execute"
    exit 1
else
    echo "✅ Cron job executed successfully"
fi

# Cleanup
echo "Cleaning up..."
docker stop postgres-test
docker rm postgres-test

echo "All tests passed! 🎉"
