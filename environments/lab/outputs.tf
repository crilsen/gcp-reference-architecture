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
