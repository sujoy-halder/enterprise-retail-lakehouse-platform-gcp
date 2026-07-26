# Cost Governance

## Controls Included

- GKE node autoscaling with small dev defaults and larger prod capacity.
- Cloud Storage lifecycle rules for bronze, temp, and quarantine data.
- Pub/Sub message retention limited to seven days.
- BigQuery partitioning and clustering on major marts.
- Snowflake warehouses configured as XSMALL with auto-suspend.
- Databricks job clusters use autoscaling rather than always-on all-purpose clusters.

## Recommended Additions

- GCP budget alerts per environment.
- BigQuery slot reservations for predictable production workloads.
- Databricks cluster policies to cap worker counts.
- Snowflake resource monitors.
- Daily cost export to BigQuery and a FinOps dbt mart.

