resource "google_project_service" "service" {
  for_each = var.services

  project                    = var.project_id
  service                    = each.key
  disable_dependent_services = false
  disable_on_destroy         = false
}

