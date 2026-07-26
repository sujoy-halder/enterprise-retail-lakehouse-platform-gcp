# Enterprise Retail Lakehouse Platform on GCP

Production-oriented reference implementation for a multi-region retail analytics platform on GCP. It covers raw ingestion, Delta Lake processing, BigQuery and Snowflake marts, Kubernetes workloads, Composer orchestration, monitoring, and GitHub Actions deployment.

## What This Deploys

- GCP foundations: APIs, VPC, regional subnets, Cloud NAT, KMS, Secret Manager, audit logging.
- Data plane: Cloud Storage lake zones, Pub/Sub topics/subscriptions, BigQuery datasets/tables/materialized views.
- Compute plane: private GKE cluster with Workload Identity Federation for GKE, ETL microservice, recommendation API, SparkApplication examples.
- Orchestration: Cloud Composer environment and Airflow DAGs for Databricks, dbt, Snowflake, and smoke checks.
- Lakehouse assets: Databricks Auto Loader, Structured Streaming, Delta Live Tables, CDC merge logic.
- Warehouse assets: dbt BigQuery models plus Snowflake database/warehouse SQL and Terraform.
- Operations: Cloud Monitoring dashboard, Grafana dashboard, retry/smoke scripts, CI and deployment workflows.

## Repository Map

```text
terraform/          GCP infrastructure modules and dev/prod envs
docker/             ETL and recommendation API containers
kubernetes/         Kustomize manifests for GKE workloads
airflow/            Composer DAGs and shared orchestration helpers
databricks/         Auto Loader, DLT, CDC, and job definitions
spark/              Spark jobs deployable through Spark Operator or Databricks
dbt/                BigQuery marts and tests
snowflake/          Cross-cloud warehouse setup
informatica/        Enterprise ETL mapping specs and parameter files
monitoring/         Grafana and Cloud Monitoring assets
scripts/            Bootstrap, validation, deployment, smoke checks
tests/              Static, schema, and contract tests
docs/               Architecture, deployment, security, operations
```

## Fast Path

1. Create or select a GCP project with billing enabled.
2. Create the Terraform state bucket:

   ```bash
   ./scripts/bootstrap_state_bucket.sh "$PROJECT_ID" "$REGION" "$PREFIX-tfstate"
   ```

3. Copy `terraform/envs/dev/terraform.tfvars.example` to `terraform/envs/dev/terraform.tfvars` and fill in the real project, repo, and region values.
4. Deploy infrastructure:

   ```bash
   terraform -chdir=terraform/envs/dev init -backend-config="bucket=$PREFIX-tfstate"
   terraform -chdir=terraform/envs/dev plan -out=tfplan
   terraform -chdir=terraform/envs/dev apply tfplan
   ```

5. Add the Terraform outputs as GitHub environment variables/secrets, then run `.github/workflows/deploy.yml`.

## Real Environment Notes

- GitHub Actions uses Workload Identity Federation, not service-account keys.
- GKE workloads use Workload Identity Federation for GKE through annotated Kubernetes service accounts.
- Buckets are encrypted with customer-managed KMS keys and use uniform bucket-level access.
- Pub/Sub subscriptions include dead-letter topics and retry settings.
- BigQuery tables are partitioned and clustered; reporting uses materialized views where useful.
- Databricks Auto Loader includes schema locations, rescued data, and schema evolution settings.
- The repo is intentionally parameterized. It will not hard-code your project IDs, account IDs, Databricks workspace, Snowflake account, or Informatica tenant.

## Deployment Order

1. `terraform apply`
2. Build and push containers to Artifact Registry
3. Deploy Kubernetes workloads to GKE
4. Sync Airflow DAGs to Composer
5. Deploy Databricks jobs/pipelines
6. Run `dbt deps`, `dbt build`
7. Apply Snowflake SQL/Terraform
8. Run smoke checks and publish SLO dashboards

See [docs/deployment.md](docs/deployment.md) for the full runbook.

## Official References Used

- [Google GitHub Actions auth](https://github.com/google-github-actions/auth)
- [GKE Workload Identity Federation](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Databricks Auto Loader schema evolution](https://docs.databricks.com/aws/en/ingestion/cloud-object-storage/auto-loader/schema)
- [dbt BigQuery configs](https://docs.getdbt.com/reference/resource-configs/bigquery-configs)
- [Snowflake Terraform provider](https://docs.snowflake.com/en/user-guide/terraform)

