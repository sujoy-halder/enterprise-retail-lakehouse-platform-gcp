output "cluster_name" {
  value = google_container_cluster.lakehouse.name
}

output "location" {
  value = google_container_cluster.lakehouse.location
}

output "endpoint" {
  value     = google_container_cluster.lakehouse.endpoint
  sensitive = true
}

