terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0, < 8.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.0, < 8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6, < 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

locals {
  environment = "prod"
  name_prefix = "${var.prefix}-${local.environment}"
  labels = merge(var.labels, {
    environment = local.environment
    platform    = "retail-lakehouse"
    managed_by  = "terraform"
  })

  required_services = [
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "composer.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "secretmanager.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com"
  ]
}

module "apis" {
  source     = "../../modules/apis"
  project_id = var.project_id
  services   = local.required_services
}

module "network" {
  source = "../../modules/network"

  project_id       = var.project_id
  name_prefix      = local.name_prefix
  region           = var.region
  secondary_region = var.secondary_region
  primary_cidr     = var.primary_subnet_cidr
  secondary_cidr   = var.secondary_subnet_cidr
  pods_cidr        = var.pods_cidr
  services_cidr    = var.services_cidr
  labels           = local.labels

  depends_on = [module.apis]
}

module "iam" {
  source = "../../modules/iam"

  project_id  = var.project_id
  name_prefix = local.name_prefix
  region      = var.region
  labels      = local.labels

  depends_on = [module.apis]
}

module "storage" {
  source = "../../modules/storage"

  project_id                     = var.project_id
  name_prefix                    = local.name_prefix
  regions                        = [var.region, var.secondary_region]
  kms_key_id                     = module.iam.kms_key_id
  force_destroy                  = false
  labels                         = local.labels
  data_service_account_email     = module.iam.data_service_account_email
  composer_service_account_email = module.iam.composer_service_account_email
}

module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id  = var.project_id
  name_prefix = local.name_prefix
  region      = var.region
  labels      = local.labels

  depends_on = [module.apis]
}

module "pubsub" {
  source = "../../modules/pubsub"

  project_id                 = var.project_id
  name_prefix                = local.name_prefix
  labels                     = local.labels
  publisher_service_accounts = [module.iam.data_service_account_email]
  subscriber_service_accounts = [
    module.iam.data_service_account_email,
    module.iam.composer_service_account_email
  ]

  depends_on = [module.apis]
}

module "bigquery" {
  source = "../../modules/bigquery"

  project_id = var.project_id
  location   = var.bigquery_location
  prefix     = replace(local.name_prefix, "-", "_")
  kms_key_id = module.iam.kms_key_id
  labels     = local.labels
}

module "gke" {
  source = "../../modules/gke"

  project_id                 = var.project_id
  name_prefix                = local.name_prefix
  region                     = var.region
  network_self_link          = module.network.network_self_link
  subnetwork_self_link       = module.network.primary_subnet_self_link
  pods_secondary_range       = module.network.pods_secondary_range_name
  services_secondary_range   = module.network.services_secondary_range_name
  master_ipv4_cidr_block     = var.master_ipv4_cidr_block
  authorized_cidr_blocks     = var.authorized_cidr_blocks
  node_service_account_email = module.iam.gke_node_service_account_email
  min_nodes                  = 3
  max_nodes                  = 12
  deletion_protection        = true
  labels                     = local.labels

  depends_on = [module.apis]
}

module "composer" {
  count  = var.deploy_composer ? 1 : 0
  source = "../../modules/composer"

  project_id                     = var.project_id
  name_prefix                    = local.name_prefix
  region                         = var.region
  network_id                     = module.network.network_id
  subnetwork_id                  = module.network.primary_subnet_id
  composer_service_account_email = module.iam.composer_service_account_email
  environment_size               = "ENVIRONMENT_SIZE_MEDIUM"
  labels                         = local.labels

  depends_on = [module.apis, module.network]
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_id         = var.project_id
  name_prefix        = local.name_prefix
  notification_email = var.billing_alert_email
  labels             = local.labels
}

module "github_oidc" {
  source = "../../modules/github-oidc"

  project_id              = var.project_id
  name_prefix             = local.name_prefix
  github_owner            = var.github_owner
  github_repo             = var.github_repo
  deploy_service_account  = "${local.name_prefix}-gha-deploy"
  artifact_repository_id  = module.artifact_registry.repository_id
  terraform_service_roles = var.github_deploy_roles
  labels                  = local.labels

  depends_on = [module.apis]
}
