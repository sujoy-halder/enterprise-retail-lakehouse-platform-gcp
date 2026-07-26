#!/usr/bin/env bash
set -euo pipefail

COMPOSER_DAG_GCS_PREFIX="${COMPOSER_DAG_GCS_PREFIX:?set COMPOSER_DAG_GCS_PREFIX from Terraform output}"
COMPOSER_DATA_PREFIX="${COMPOSER_DAG_GCS_PREFIX%/dags}/data"

gcloud storage rsync airflow/dags "${COMPOSER_DAG_GCS_PREFIX}" --recursive --delete-unmatched-destination-objects
gcloud storage rsync dbt "${COMPOSER_DATA_PREFIX}/dbt" --recursive --delete-unmatched-destination-objects
gcloud storage rsync scripts "${COMPOSER_DATA_PREFIX}/scripts" --recursive

echo "Composer assets synced to ${COMPOSER_DAG_GCS_PREFIX}"

