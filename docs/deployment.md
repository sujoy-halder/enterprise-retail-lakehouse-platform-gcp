# Deployment Runbook

## Prerequisites

- GCP project with billing enabled.
- GitHub repository with environments named `dev` and `prod`.
- Local or CI access to `gcloud`, `terraform`, `docker`, `kubectl`, `dbt`, and Python.
- Databricks workspace on GCP, if deploying Databricks jobs.
- Snowflake account, if deploying Snowflake marts.

## One-time Bootstrap

```bash
export PROJECT_ID=your-gcp-project-id
export REGION=us-central1
export PREFIX=retail-lakehouse

./scripts/bootstrap_state_bucket.sh "$PROJECT_ID" "$REGION" "$PREFIX-tfstate"
```

Create `terraform/envs/dev/terraform.tfvars` from the example and run:

```bash
terraform -chdir=terraform/envs/dev init -backend-config="bucket=$PREFIX-tfstate" -backend-config="prefix=dev"
terraform -chdir=terraform/envs/dev plan -out=tfplan
terraform -chdir=terraform/envs/dev apply tfplan
```

## GitHub Environment Variables

Set these from Terraform outputs:

- `GCP_PROJECT_ID`
- `GCP_REGION`
- `PLATFORM_PREFIX`
- `TERRAFORM_STATE_BUCKET`
- `GCP_WORKLOAD_IDENTITY_PROVIDER`
- `GCP_DEPLOY_SERVICE_ACCOUNT`
- `BIGQUERY_LOCATION`

Optional:

- `DATABRICKS_HOST`
- `DATABRICKS_PIPELINE_ID`

Secrets:

- `DATABRICKS_TOKEN`
- Snowflake credentials, if CI will apply Snowflake assets.

## Deploy

Run `.github/workflows/deploy.yml` with the target environment. The workflow applies Terraform, builds containers, deploys GKE manifests, syncs Composer DAGs, runs dbt, optionally uploads Databricks assets, and runs smoke tests.

## Private GKE Control Plane

The default cluster uses private nodes and an authorized public control-plane endpoint. For stricter production, set the endpoint private and run deployment from a self-hosted GitHub runner inside the VPC or over VPN.

