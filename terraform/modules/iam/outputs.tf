output "kms_key_id" {
  value = google_kms_crypto_key.data.id
}

output "data_service_account_email" {
  value = google_service_account.platform["data"].email
}

output "composer_service_account_email" {
  value = google_service_account.platform["composer"].email
}

output "gke_node_service_account_email" {
  value = google_service_account.platform["gke_node"].email
}

output "dbt_service_account_email" {
  value = google_service_account.platform["dbt"].email
}

output "secret_ids" {
  value = {
    for key, secret in google_secret_manager_secret.platform : key => secret.id
  }
}

