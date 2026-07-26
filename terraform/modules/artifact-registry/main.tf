resource "google_artifact_registry_repository" "containers" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.name_prefix}-containers"
  description   = "Retail lakehouse container images."
  format        = "DOCKER"
  labels        = var.labels

  docker_config {
    immutable_tags = true
  }
}

