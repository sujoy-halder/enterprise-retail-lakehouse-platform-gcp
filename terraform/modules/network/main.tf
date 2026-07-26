resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
  description             = "Private network for the retail lakehouse platform."
}

resource "google_compute_subnetwork" "primary" {
  project                  = var.project_id
  name                     = "${var.name_prefix}-${var.region}-data"
  region                   = var.region
  ip_cidr_range            = var.primary_cidr
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "${var.name_prefix}-pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "${var.name_prefix}-services"
    ip_cidr_range = var.services_cidr
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "secondary" {
  project                  = var.project_id
  name                     = "${var.name_prefix}-${var.secondary_region}-data"
  region                   = var.secondary_region
  ip_cidr_range            = var.secondary_cidr
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "primary" {
  project = var.project_id
  name    = "${var.name_prefix}-${var.region}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "primary" {
  project                            = var.project_id
  name                               = "${var.name_prefix}-${var.region}-nat"
  router                             = google_compute_router.primary.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.primary.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_router" "secondary" {
  project = var.project_id
  name    = "${var.name_prefix}-${var.secondary_region}-router"
  region  = var.secondary_region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "secondary" {
  project                            = var.project_id
  name                               = "${var.name_prefix}-${var.secondary_region}-nat"
  router                             = google_compute_router.secondary.name
  region                             = var.secondary_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.secondary.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "allow_internal" {
  project = var.project_id
  name    = "${var.name_prefix}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.primary_cidr, var.secondary_cidr, var.pods_cidr, var.services_cidr]
}

resource "google_dns_managed_zone" "googleapis_private" {
  project     = var.project_id
  name        = "${var.name_prefix}-googleapis-private"
  dns_name    = "googleapis.com."
  description = "Private Google APIs DNS for GKE workloads using Private Google Access."
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc.id
    }
  }
}

resource "google_dns_record_set" "private_googleapis_a" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.googleapis_private.name
  name         = "private.googleapis.com."
  type         = "A"
  ttl          = 300
  rrdatas      = ["199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"]
}

resource "google_dns_record_set" "wildcard_googleapis_cname" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.googleapis_private.name
  name         = "*.googleapis.com."
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["private.googleapis.com."]
}
