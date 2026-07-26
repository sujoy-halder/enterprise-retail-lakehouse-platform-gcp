output "artifact_registry_url" {
  value       = module.artifact_registry.repository_url
  description = "Docker repository URL for CI image pushes."
}

output "gke_cluster_name" {
  value       = module.gke.cluster_name
  description = "GKE cluster name."
}

output "gke_location" {
  value       = module.gke.location
  description = "GKE cluster location."
}

output "composer_dag_gcs_prefix" {
  value       = try(module.composer[0].dag_gcs_prefix, null)
  description = "Composer DAG bucket prefix."
}

output "lake_buckets" {
  value       = module.storage.bucket_names
  description = "Lake storage buckets by layer and region."
}

output "pubsub_topics" {
  value       = module.pubsub.topic_names
  description = "Retail source Pub/Sub topics."
}

output "bigquery_datasets" {
  value       = module.bigquery.dataset_ids
  description = "BigQuery dataset IDs."
}

output "gke_workload_service_account" {
  value       = module.iam.data_service_account_email
  description = "GCP service account for GKE application workloads."
}

output "github_workload_identity_provider" {
  value       = module.github_oidc.workload_identity_provider
  description = "Provider string for google-github-actions/auth."
}

output "github_deploy_service_account" {
  value       = module.github_oidc.deploy_service_account_email
  description = "Service account impersonated by GitHub Actions."
}

