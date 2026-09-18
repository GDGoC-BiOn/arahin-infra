output "network_id" {
  value = google_compute_network.this.id
}

output "network_self_link" {
  value = google_compute_network.this.self_link
}

output "run_subnet_id" {
  value = google_compute_subnetwork.run.id
}

# Cloud SQL must wait for the peering connection before it can request a
# private IP in that range — depend on this output (or on the module as a
# whole) from anything that needs the private network ready.
output "private_vpc_connection_id" {
  value = google_service_networking_connection.private_vpc.id
}
