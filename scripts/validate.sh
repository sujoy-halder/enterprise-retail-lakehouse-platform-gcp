#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"

if command -v terraform >/dev/null 2>&1; then
  terraform fmt -check -recursive terraform
  terraform -chdir="terraform/envs/${ENVIRONMENT}" init -backend=false
  terraform -chdir="terraform/envs/${ENVIRONMENT}" validate
else
  echo "terraform not found; skipping Terraform validation." >&2
fi

if command -v python >/dev/null 2>&1; then
  python -m pytest tests
else
  echo "python not found; skipping tests." >&2
fi

if command -v dbt >/dev/null 2>&1; then
  cp dbt/retail_analytics/profiles.yml.example dbt/retail_analytics/profiles.yml
  (cd dbt/retail_analytics && dbt deps && dbt parse --profiles-dir .)
else
  echo "dbt not found; skipping dbt parse." >&2
fi

