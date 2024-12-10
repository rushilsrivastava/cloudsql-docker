# postgis-cloudsql-docker

This Docker image is based on [PostGIS](https://hub.docker.com/r/postgis/postgis), [pg_cron](https://github.com/citusdata/pg_cron), and [postgres_hll](https://github.com/citusdata/postgresql-hll). Other extensions may be added in the future with the goal of eventually mirroring the [GCP CloudSQL extensions](https://cloud.google.com/sql/docs/postgres/extensions).

### NOTE: Not all extensions have been added yet. See an extension missing? [Open an issue](https://github.com/rushilsrivastava/postgres-cloudsql-docker/issues/new) or submit a pull request.

Supported extensions:

- postgis
- pg_cron
- postgres_hll
