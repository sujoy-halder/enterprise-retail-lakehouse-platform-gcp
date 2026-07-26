output "name" {
  value = google_composer_environment.lakehouse.name
}

output "dag_gcs_prefix" {
  value = google_composer_environment.lakehouse.config[0].dag_gcs_prefix
}

