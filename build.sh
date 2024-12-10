#!/bin/bash

# PostgreSQL versions to build
PG_VERSIONS=("14" "15" "16" "17")

# PostGIS version
POSTGIS_VERSION="3.5"

# HLL version
HLL_VERSION="2.18"

# Repository name
REPO="rushilsrivastava/postgis-cloudsql"

# Build and push images for each PostgreSQL version
for version in "${PG_VERSIONS[@]}"; do
    echo "Building PostgreSQL ${version} with PostGIS ${POSTGIS_VERSION} and HLL ${HLL_VERSION}..."
    docker build \
        --build-arg PG_VERSION=${version} \
        --build-arg POSTGIS_VERSION=${POSTGIS_VERSION} \
        --build-arg HLL_VERSION=${HLL_VERSION} \
        -t ${REPO}:${version} \
        -t ${REPO}:${version}-postgis${POSTGIS_VERSION} \
        -t ${REPO}:${version}-postgis${POSTGIS_VERSION}-hll${HLL_VERSION} \
        -t ${REPO}:${version}-hll${HLL_VERSION} \
        .
    
    if [ $? -eq 0 ]; then
        echo "Successfully built image for PostgreSQL ${version}"
        docker push ${REPO}:${version}
        docker push ${REPO}:${version}-postgis${POSTGIS_VERSION}
        docker push ${REPO}:${version}-postgis${POSTGIS_VERSION}-hll${HLL_VERSION}
    else
        echo "Failed to build image for PostgreSQL ${version}"
        exit 1
    fi
done
