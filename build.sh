#!/bin/bash

# PostgreSQL versions to build
PG_VERSIONS=("14" "15" "16" "17")

# PostGIS version
POSTGIS_VERSION="3.5"

# Repository name
REPO="rushilsrivastava/postgis-cloudsql"

# Build and push images for each PostgreSQL version
for version in "${PG_VERSIONS[@]}"; do
    echo "Building PostgreSQL ${version} with PostGIS ${POSTGIS_VERSION}..."
    docker build \
        --build-arg PG_VERSION=${version} \
        --build-arg POSTGIS_VERSION=${POSTGIS_VERSION} \
        -t ${REPO}:${version} \
        -t ${REPO}:${version}-postgis${POSTGIS_VERSION} \
        .
    
    if [ $? -eq 0 ]; then
        echo "Successfully built PostgreSQL ${version} with PostGIS ${POSTGIS_VERSION}"
    else
        echo "Failed to build PostgreSQL ${version}"
        exit 1
    fi
done

echo "All builds completed successfully!"
