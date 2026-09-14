# AWS conceptual equivalent: Organizational Unit in AWS Organizations
# GCP implementation: Resource Manager Folder
resource "google_folder" "workloads" {
  display_name        = var.folder_name
  parent              = "organizations/${var.organization_id}"
  deletion_protection = true
}

# AWS conceptual equivalent: member account
# GCP implementation: Google Cloud project
resource "google_project" "lab" {
  name                = "Kubernetes Lab"
  project_id          = var.lab_project_id
  folder_id           = google_folder.workloads.folder_id
  billing_account     = var.billing_account_id
  deletion_policy     = "PREVENT"
  auto_create_network = false
  labels              = { environment = "lab", managed_by = "terraform" }
}

resource "google_project" "production" {
  name                = "Kubernetes Production"
  project_id          = var.production_project_id
  folder_id           = google_folder.workloads.folder_id
  billing_account     = var.billing_account_id
  deletion_policy     = "PREVENT"
  auto_create_network = false
  labels              = { environment = "production", managed_by = "terraform" }
}
