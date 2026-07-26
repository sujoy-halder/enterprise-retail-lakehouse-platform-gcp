output "network_id" {
  value = google_compute_network.vpc.id
}

output "network_self_link" {
  value = google_compute_network.vpc.self_link
}

output "primary_subnet_id" {
  value = google_compute_subnetwork.primary.id
}

output "primary_subnet_self_link" {
  value = google_compute_subnetwork.primary.self_link
}

output "secondary_subnet_id" {
  value = google_compute_subnetwork.secondary.id
}

output "pods_secondary_range_name" {
  value = google_compute_subnetwork.primary.secondary_ip_range[0].range_name
}

output "services_secondary_range_name" {
  value = google_compute_subnetwork.primary.secondary_ip_range[1].range_name
}

