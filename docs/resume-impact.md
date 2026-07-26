# Resume Impact

Suggested resume bullet:

Built a production-style enterprise retail lakehouse on GCP using Terraform, GKE, Pub/Sub, Cloud Storage, Databricks Delta Live Tables, Spark Structured Streaming, BigQuery, Snowflake, dbt, Composer, and GitHub Actions; implemented Workload Identity, KMS encryption, private networking, CDC merges, schema evolution, data quality checks, autoscaling, and SLO dashboards.

Interview talking points:

- Why bronze/silver/gold separates replayability from business semantics.
- How Auto Loader handles schema evolution and rescued data.
- How CDC merge logic differs between DLT `apply_changes`, Delta `MERGE`, and warehouse incremental models.
- Why GitHub OIDC and GKE Workload Identity avoid long-lived keys.
- How partitioning, clustering, and materialized views reduce BigQuery cost.
- How to operate Pub/Sub backlogs and dead-letter queues.

