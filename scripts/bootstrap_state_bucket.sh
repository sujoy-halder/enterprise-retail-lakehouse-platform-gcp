#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${1:?usage: bootstrap_state_bucket.sh PROJECT_ID REGION BUCKET_NAME}"
REGION="${2:?usage: bootstrap_state_bucket.sh PROJECT_ID REGION BUCKET_NAME}"
BUCKET_NAME="${3:?usage: bootstrap_state_bucket.sh PROJECT_ID REGION BUCKET_NAME}"

gcloud config set project "$PROJECT_ID" >/dev/null
gcloud services enable storage.googleapis.com cloudkms.googleapis.com serviceusage.googleapis.com

if ! gcloud storage buckets describe "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
  gcloud storage buckets create "gs://${BUCKET_NAME}" \
    --project="$PROJECT_ID" \
    --location="$REGION" \
    --uniform-bucket-level-access
fi

gcloud storage buckets update "gs://${BUCKET_NAME}" \
  --versioning \
  --public-access-prevention \
  --retention-period=7d

echo "Terraform state bucket ready: gs://${BUCKET_NAME}"

