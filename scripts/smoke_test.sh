#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${PROJECT_ID:?set PROJECT_ID}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
PREFIX="${PREFIX:-retail-lakehouse}"
BQ_PREFIX="${BIGQUERY_DATASET_PREFIX:-${PREFIX//-/_}_${ENVIRONMENT}}"

echo "Checking Pub/Sub topics..."
gcloud pubsub topics describe "${PREFIX}-${ENVIRONMENT}-pos-transactions" --project "$PROJECT_ID" >/dev/null

echo "Checking BigQuery datasets..."
bq --project_id="$PROJECT_ID" show "${BQ_PREFIX}_gold" >/dev/null

if command -v kubectl >/dev/null 2>&1; then
  echo "Checking GKE deployments..."
  kubectl -n retail-lakehouse rollout status deploy/retail-etl-service --timeout=120s
  kubectl -n retail-lakehouse rollout status deploy/retail-recommendation-api --timeout=120s
else
  echo "kubectl not found; skipping Kubernetes rollout checks."
fi

echo "Smoke checks passed."

