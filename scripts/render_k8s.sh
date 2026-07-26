#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-${ENVIRONMENT:-dev}}"
OVERLAY="kubernetes/overlays/${ENVIRONMENT}"

required=(
  PROJECT_ID
  REGION
  ENVIRONMENT
  ARTIFACT_REGISTRY
  IMAGE_TAG
  GCP_WORKLOAD_SERVICE_ACCOUNT
  BRONZE_BUCKET
  SILVER_BUCKET
  CHECKPOINT_BUCKET
  QUARANTINE_BUCKET
  POS_SUBSCRIPTION
  INVENTORY_SUBSCRIPTION
  BIGQUERY_DATASET_PREFIX
)

for name in "${required[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: ${name}" >&2
    exit 1
  fi
done

if command -v kubectl >/dev/null 2>&1; then
  rendered="$(kubectl kustomize "$OVERLAY")"
elif command -v kustomize >/dev/null 2>&1; then
  rendered="$(kustomize build "$OVERLAY")"
else
  echo "kubectl or kustomize is required to render Kubernetes manifests." >&2
  exit 1
fi

if command -v envsubst >/dev/null 2>&1; then
  printf "%s" "$rendered" | envsubst
else
  printf "%s" "$rendered" | python scripts/envsubst.py
fi
