# Org policy constraints/sql.restrictPublicIp forbids a public IP on Cloud
# SQL, so the instance needs a private IP instead — which means a VPC, a
# peering range for Google-managed services, and a subnet Cloud Run can reach
# it through via Direct VPC egress (no VPC Access Connector needed).

resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "run" {
  project       = var.project_id
  name          = "${var.name}-run"
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = var.run_subnet_cidr
}

resource "google_compute_global_address" "private_ip_range" {
  project       = var.project_id
  name          = "${var.name}-sql-peering"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.this.id
}

resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.this.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}
