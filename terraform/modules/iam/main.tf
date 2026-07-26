locals {
  sa_prefix = substr(replace(var.name_prefix, "_", "-"), 0, 19)

  service_accounts = {
    data     = "${local.sa_prefix}-data"
    composer = "${local.sa_prefix}-composer"
    gke_node = "${local.sa_prefix}-gke-node"
    dbt      = "${local.sa_prefix}-dbt"
  }

  project_roles = {
    data = [
      "roles/bigquery.dataEditor",
      "roles/bigquery.jobUser",
      "roles/cloudkms.cryptoKeyEncrypterDecrypter",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/pubsub.publisher",
      "roles/pubsub.subscriber",
      "roles/secretmanager.secretAccessor",
      "roles/storage.objectAdmin"
    ]
    composer = [
      "roles/bigquery.jobUser",
      "roles/composer.worker",
      "roles/dataproc.editor",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/pubsub.subscriber",
      "roles/secretmanager.secretAccessor",
      "roles/storage.objectAdmin"
    ]
    gke_node = [
      "roles/artifactregistry.reader",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter"
    ]
    dbt = [
      "roles/bigquery.dataEditor",
      "roles/bigquery.jobUser",
      "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    ]
  }

  flattened_roles = flatten([
    for account_key, roles in local.project_roles : [
      for role in roles : {
        account_key = account_key
        role        = role
      }
    ]
  ])

  secret_names = [
    "databricks-host",
    "databricks-token",
    "snowflake-account",
    "snowflake-user",
    "snowflake-private-key",
    "informatica-base-url",
    "informatica-client-id",
    "informatica-client-secret"
  ]
}

data "google_bigquery_default_service_account" "bq" {
  project = var.project_id
}

data "google_storage_project_service_account" "gcs" {
  project = var.project_id
}

resource "google_service_account" "platform" {
  for_each = local.service_accounts

  project      = var.project_id
  account_id   = each.value
  display_name = "Retail lakehouse ${each.key} service account"
}

resource "google_project_iam_member" "platform_roles" {
  for_each = {
    for item in local.flattened_roles : "${item.account_key}-${item.role}" => item
  }

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.platform[each.value.account_key].email}"
}

resource "google_kms_key_ring" "lakehouse" {
  project  = var.project_id
  name     = replace("${var.name_prefix}-keyring", "-", "_")
  location = var.region
}

resource "google_kms_crypto_key" "data" {
  name            = "data-platform"
  key_ring        = google_kms_key_ring.lakehouse.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_member" "bigquery_cmek" {
  crypto_key_id = google_kms_crypto_key.data.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_bigquery_default_service_account.bq.email}"
}

resource "google_kms_crypto_key_iam_member" "storage_cmek" {
  crypto_key_id = google_kms_crypto_key.data.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs.email_address}"
}

resource "google_service_account_iam_member" "gke_workload_identity_user" {
  service_account_id = google_service_account.platform["data"].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[retail-lakehouse/retail-workloads]"
}

resource "google_secret_manager_secret" "platform" {
  for_each = toset(local.secret_names)

  project   = var.project_id
  secret_id = "${var.name_prefix}-${each.key}"
  labels    = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "data_accessor" {
  for_each = google_secret_manager_secret.platform

  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.platform["data"].email}"
}

resource "google_secret_manager_secret_iam_member" "composer_accessor" {
  for_each = google_secret_manager_secret.platform

  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.platform["composer"].email}"
}

resource "google_project_iam_audit_config" "data_access" {
  for_each = toset([
    "bigquery.googleapis.com",
    "pubsub.googleapis.com",
    "storage.googleapis.com"
  ])

  project = var.project_id
  service = each.key

  audit_log_config {
    log_type = "ADMIN_READ"
  }

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }
}
