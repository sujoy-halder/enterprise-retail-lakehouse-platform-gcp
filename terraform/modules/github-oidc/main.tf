data "google_project" "current" {
  project_id = var.project_id
}

locals {
  pool_id           = substr(replace("${var.name_prefix}-gha", "_", "-"), 0, 32)
  provider_id       = "github"
  deploy_account_id = substr(replace(var.deploy_service_account, "_", "-"), 0, 30)
  repo_attribute    = "${var.github_owner}/${var.github_repo}"
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = local.pool_id
  display_name              = "${var.name_prefix} GitHub Actions"
  description               = "OIDC trust for GitHub Actions deployments."
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = local.provider_id
  display_name                       = "GitHub"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  attribute_condition = "assertion.repository == '${local.repo_attribute}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "deploy" {
  project      = var.project_id
  account_id   = local.deploy_account_id
  display_name = "Retail lakehouse GitHub deployer"
}

resource "google_service_account_iam_member" "github_workload_identity" {
  service_account_id = google_service_account.deploy.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${local.repo_attribute}"
}

resource "google_project_iam_member" "deploy_roles" {
  for_each = toset(var.terraform_service_roles)

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.deploy.email}"
}

resource "google_project_iam_member" "deploy_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.deploy.email}"
}
