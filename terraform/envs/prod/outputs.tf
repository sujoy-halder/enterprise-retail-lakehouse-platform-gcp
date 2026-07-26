output "artifact_registry_url" {
  value = module.artifact_registry.repository_url
}

output "gke_cluster_name" {
  value = module.gke.cluster_name
}

output "gke_location" {
  value = module.gke.location
}

output "composer_dag_gcs_prefix" {
  value = try(module.composer[0].dag_gcs_prefix, null)
}

output "github_workload_identity_provider" {
  value = module.github_oidc.workload_identity_provider
}

output "github_deploy_service_account" {
  value = module.github_oidc.deploy_service_account_email
}
