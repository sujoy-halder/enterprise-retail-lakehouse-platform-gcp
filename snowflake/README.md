# Snowflake Deployment

Use Terraform for stable account objects and SQL for reviewable grants, stages, and marts.

```bash
cd snowflake/terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Authentication is intentionally not committed. Configure the Snowflake provider through environment variables or your CI secret store.

Run SQL in order:

1. `sql/001_foundation.sql`
2. `sql/010_marts.sql`
3. `sql/020_gcs_stage_template.sql`

The GCS integration flow requires approving the generated GCP service account shown by `DESC STORAGE INTEGRATION`.

