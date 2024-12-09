#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BLUE='\033[0;34m'

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Function to handle errors
handle_error() {
    echo -e "\n${RED}Error: $1${NC}"
    # Clean up on error
    docker rm -f postgres-test 2>/dev/null || true
    docker rmi -f postgis-cloudsql:test 2>/dev/null || true
    exit 1
}

# Clean up any existing containers/images
print_header "Cleaning up previous test artifacts"
docker rm -f postgres-test 2>/dev/null || true
docker rmi -f postgis-cloudsql:test 2>/dev/null || true

# Build the image
print_header "Building Docker image"
docker build -t postgis-cloudsql:test . || handle_error "Failed to build Docker image"

# Run the tests
print_header "Running tests"
./tests/test_pg_cron.sh || handle_error "Tests failed"

# Clean up
print_header "Final cleanup"
docker rm -f postgres-test 2>/dev/null || true
docker rmi -f postgis-cloudsql:test 2>/dev/null || true

echo -e "\n${GREEN}All tests passed successfully!${NC}\n"
