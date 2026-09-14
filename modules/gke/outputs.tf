output "cluster_name" { value = google_container_cluster.this.name }
output "cluster_location" { value = google_container_cluster.this.location }
output "cluster_endpoint" {
  value     = google_container_cluster.this.endpoint
  sensitive = true
}
output "node_service_account" { value = google_service_account.nodes.email }
output "artifact_registry_repository" { value = google_artifact_registry_repository.containers.name }
