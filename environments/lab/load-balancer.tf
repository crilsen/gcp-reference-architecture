resource "google_compute_global_address" "hello_world" {
  project      = var.project_id
  name         = "hello-world-ip"
  description  = "Static external IP used by the GKE hello-world Ingress."
  address_type = "EXTERNAL"
  ip_version   = "IPV4"

  depends_on = [google_project_service.required]
}
