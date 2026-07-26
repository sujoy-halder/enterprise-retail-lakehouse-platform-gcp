#!/usr/bin/env bash
set -euo pipefail

: "${DATABRICKS_HOST:?set DATABRICKS_HOST}"
: "${DATABRICKS_TOKEN:?set DATABRICKS_TOKEN}"
: "${BRONZE_BUCKET:?set BRONZE_BUCKET from Terraform output}"
: "${CHECKPOINT_BUCKET:?set CHECKPOINT_BUCKET from Terraform output}"

if ! command -v databricks >/dev/null 2>&1; then
  echo "databricks CLI is required." >&2
  exit 1
fi

databricks fs mkdirs dbfs:/retail/jobs
databricks fs cp databricks/jobs/retail_streaming_autoloader.py dbfs:/retail/jobs/retail_streaming_autoloader.py --overwrite
databricks workspace mkdirs /Shared/retail-lakehouse/dlt
databricks workspace import databricks/dlt/retail_bronze_silver_dlt.py /Shared/retail-lakehouse/dlt/retail_bronze_silver_dlt --language PYTHON --format SOURCE --overwrite

pipeline_settings="$(mktemp)"
trap 'rm -f "$pipeline_settings"' EXIT
python scripts/envsubst.py < databricks/jobs/dlt_pipeline_settings.json > "$pipeline_settings"

if [[ -n "${DATABRICKS_PIPELINE_ID:-}" ]]; then
  databricks pipelines update "$DATABRICKS_PIPELINE_ID" --json @"$pipeline_settings"
else
  echo "DATABRICKS_PIPELINE_ID not set; skipping DLT pipeline update."
fi
