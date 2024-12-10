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

echo "Testing hll installation..."

# Creating extension hll
echo "Installing hll extension..."
run_sql "CREATE EXTENSION IF NOT EXISTS hll;"

# Verify extension
echo "Checking hll extension..."
if ! run_sql "SELECT extname, extversion FROM pg_extension WHERE extname = 'hll';" | grep -q "hll"; then
    echo " hll extension is not installed"
    exit 1
fi
echo " hll extension is installed"

# Test basic HLL functionality
echo "Testing basic HLL functionality..."
run_sql "CREATE TABLE test_hll (id serial primary key, sketch hll);"
run_sql "INSERT INTO test_hll (sketch) VALUES (hll_empty());"
run_sql "UPDATE test_hll SET sketch = hll_add(sketch, 1) WHERE id = 1;"
if ! run_sql "SELECT hll_cardinality(sketch) FROM test_hll WHERE id = 1;" | grep -q "1"; then
    echo " Basic HLL functionality test failed"
    exit 1
fi
echo " Basic HLL functionality test passed"

# Clean up
echo "Cleaning up..."
docker stop postgres-test
docker rm postgres-test

echo "All tests passed!"
