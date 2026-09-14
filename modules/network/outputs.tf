output "network_id" { value = google_compute_network.this.id }
output "network_name" { value = google_compute_network.this.name }
output "subnetwork_id" { value = google_compute_subnetwork.nodes.id }
output "subnetwork_name" { value = google_compute_subnetwork.nodes.name }
output "router_name" { value = try(google_compute_router.this[0].name, null) }
output "nat_name" { value = try(google_compute_router_nat.this[0].name, null) }

