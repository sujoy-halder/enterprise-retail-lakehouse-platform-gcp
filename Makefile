SHELL := /usr/bin/env bash
ENV ?= dev
TF_DIR := terraform/envs/$(ENV)
PROJECT_ID ?=
REGION ?= us-central1

.PHONY: help fmt validate test docker-build terraform-init terraform-plan terraform-apply k8s-render smoke

help:
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-24s %s\n", $$1, $$2}'

fmt: ## Format Terraform and Python.
	terraform fmt -recursive terraform
	python -m ruff format docker tests || true

validate: ## Validate Terraform modules and static project contracts.
	bash scripts/validate.sh $(ENV)

test: ## Run unit and integration tests.
	python -m pytest tests

terraform-init: ## Initialize Terraform for ENV=dev|prod.
	terraform -chdir=$(TF_DIR) init

terraform-plan: ## Create a Terraform plan.
	terraform -chdir=$(TF_DIR) plan -out=tfplan

terraform-apply: ## Apply a previously reviewed Terraform plan.
	terraform -chdir=$(TF_DIR) apply tfplan

docker-build: ## Build both platform containers locally.
	docker build -f docker/etl-service/Dockerfile -t retail-etl-service:local .
	docker build -f docker/recommendation-api/Dockerfile -t retail-recommendation-api:local .

k8s-render: ## Render Kubernetes manifests with local environment variables.
	bash scripts/render_k8s.sh $(ENV)

smoke: ## Run post-deployment smoke checks.
	bash scripts/smoke_test.sh
