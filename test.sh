#!/bin/bash

# Check if a test script was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <test_script>"
    echo "Example: $0 test_pg_cron.sh"
    exit 1
fi

TEST_SCRIPT=$1

# Ensure the test script exists
if [ ! -f "$TEST_SCRIPT" ]; then
    echo "Test script $TEST_SCRIPT not found!"
    exit 1
fi

# Default versions (matching the workflow defaults)
PG_VERSION=${PG_VERSION:-15}
POSTGIS_VERSION=${POSTGIS_VERSION:-3.5}
HLL_VERSION=${HLL_VERSION:-2.18}

# Function to clean up
cleanup() {
    echo "Cleaning up..."
    docker rmi -f postgis-cloudsql:test >/dev/null 2>&1 || true
    docker rm -f postgres-test >/dev/null 2>&1 || true
}

# Ensure cleanup happens even on error
trap cleanup EXIT

echo "Building test image..."
docker build \
    --build-arg PG_VERSION=${PG_VERSION} \
    --build-arg POSTGIS_VERSION=${POSTGIS_VERSION} \
    --build-arg HLL_VERSION=${HLL_VERSION} \
    -t postgis-cloudsql:test .

# Make the test script executable
chmod +x "$TEST_SCRIPT"

echo "Running test: $TEST_SCRIPT"
"./$TEST_SCRIPT"

# The cleanup will happen automatically due to the trap
