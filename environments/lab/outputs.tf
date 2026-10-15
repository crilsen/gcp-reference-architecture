output "cluster_name" { value = module.gke.cluster_name }
output "cluster_location" { value = module.gke.cluster_location }
output "network_name" { value = module.network.network_name }
output "subnetwork_name" { value = module.network.subnetwork_name }
output "cloud_router_name" { value = module.network.router_name }
output "cloud_nat_name" { value = module.network.nat_name }
output "artifact_registry_repository" { value = module.gke.artifact_registry_repository }
output "hello_world_public_ip" { value = google_compute_global_address.hello_world.address }
output "get_credentials_command" {
  value = "gcloud container clusters get-credentials ${module.gke.cluster_name} --zone ${module.gke.cluster_location} --project ${var.project_id}"
}
output "neg_name" { value = var.neg_name }
output "certificate_map_name" { value = google_certificate_manager_certificate_map.hello_world.name }
output "dns_authorization_record" {
  description = "DNS record to create so Certificate Manager can issue the Google-managed certificate."
  value       = google_certificate_manager_dns_authorization.hello_world.dns_resource_record
}
output "cloud_armor_policy_name" {
  value = var.enable_cloud_armor ? google_compute_security_policy.hello_world[0].name : null
}
