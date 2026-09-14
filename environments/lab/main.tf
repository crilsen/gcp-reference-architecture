provider "google" {
  project = var.project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

locals {
  labels = {
    environment = "lab"
    managed_by  = "terraform"
    project     = var.project_name
  }
  required_services = toset([
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ])
}

resource "google_project_service" "required" {
  for_each           = local.required_services
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

module "network" {
  source           = "../../modules/network"
  project_id       = var.project_id
  name             = var.project_name
  region           = var.gcp_region
  subnet_cidr      = var.network_cidr
  pod_cidr         = var.pod_cidr
  service_cidr     = var.service_cidr
  enable_cloud_nat = true
  depends_on       = [google_project_service.required]
}

module "gke" {
  source                     = "../../modules/gke"
  project_id                 = var.project_id
  name                       = var.project_name
  region                     = var.gcp_region
  zone                       = var.gcp_zone
  network_id                 = module.network.network_id
  subnetwork_id              = module.network.subnetwork_id
  pods_range_name            = "${var.project_name}-pods"
  services_range_name        = "${var.project_name}-services"
  master_ipv4_cidr           = var.master_ipv4_cidr
  master_authorized_networks = var.master_authorized_networks
  kubernetes_version         = var.kubernetes_version
  node_machine_type          = var.node_machine_type
  node_disk_size_gb          = var.node_disk_size_gb
  node_min_count             = var.node_min_count
  node_max_count             = var.node_max_count
  node_spot                  = var.node_spot
  deletion_protection        = var.deletion_protection
  labels                     = local.labels
  depends_on                 = [google_project_service.required]
}

