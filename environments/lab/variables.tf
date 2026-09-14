variable "project_id" {
  description = "Existing Google Cloud project where the lab is deployed."
  type        = string
}

variable "gcp_region" {
  description = "Google Cloud region used by the lab."
  type        = string
}

variable "gcp_zone" {
  description = "Single zone used by the cost-conscious GKE lab."
  type        = string
}

variable "project_name" {
  description = "Generic prefix for Google Cloud lab resources."
  type        = string
}

variable "kubernetes_version" {
  description = "Minimum GKE control-plane version. The REGULAR channel manages subsequent patches."
  type        = string
}

variable "network_cidr" { type = string }
variable "pod_cidr" { type = string }
variable "service_cidr" { type = string }
variable "master_ipv4_cidr" { type = string }

variable "master_authorized_networks" {
  description = "Public CIDRs allowed to reach the GKE control-plane endpoint. Use your public IPv4/32."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  validation {
    condition     = length(var.master_authorized_networks) > 0 && alltrue([for network in var.master_authorized_networks : network.cidr_block != "0.0.0.0/0"])
    error_message = "Provide at least one restricted administrator CIDR; 0.0.0.0/0 is refused."
  }
}

variable "node_machine_type" { type = string }
variable "node_disk_size_gb" { type = number }
variable "node_min_count" { type = number }
variable "node_max_count" { type = number }
variable "node_spot" { type = bool }
variable "deletion_protection" { type = bool }
