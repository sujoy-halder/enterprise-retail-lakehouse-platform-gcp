# Operations

## SLOs

- Pub/Sub oldest unacked message age: less than 15 minutes.
- ETL service availability: 99.9 percent monthly.
- Daily marts freshness: less than 2 hours behind source events.
- Dead-letter rate: less than 0.1 percent of source messages.

## Runbooks

### Pub/Sub Backlog

1. Check the `oldest_unacked_message_age` alert.
2. Inspect subscriber errors in Cloud Logging.
3. Scale ETL workloads or Databricks workers.
4. Replay from subscriptions after fixing bad payloads.

### Databricks Schema Evolution Failure

1. Inspect the Auto Loader schema location in the checkpoint bucket.
2. Review `_rescued_data` examples.
3. Add explicit schema hints if a type widened unexpectedly.
4. Restart the failed stream after the schema update is committed.

### BigQuery Cost Spike

1. Query `INFORMATION_SCHEMA.JOBS_BY_PROJECT`.
2. Identify unpartitioned scans.
3. Add partition filters or clustering.
4. Promote repeated heavy BI queries to materialized views.

## Release Checklist

- Terraform plan reviewed.
- Docker images built with immutable tags.
- dbt build passes.
- Smoke tests pass.
- Cloud Monitoring dashboard updated.
- Rollback image tag documented.

