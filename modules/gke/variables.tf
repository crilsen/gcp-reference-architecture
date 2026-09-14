variable "project_id" { type = string }
variable "name" { type = string }
variable "region" { type = string }
variable "zone" { type = string }
variable "network_id" { type = string }
variable "subnetwork_id" { type = string }
variable "pods_range_name" { type = string }
variable "services_range_name" { type = string }
variable "master_ipv4_cidr" { type = string }
variable "master_authorized_networks" {
  type = list(object({ cidr_block = string, display_name = string }))
}
variable "kubernetes_version" { type = string }
variable "node_machine_type" { type = string }
variable "node_disk_size_gb" { type = number }
variable "node_min_count" { type = number }
variable "node_max_count" { type = number }
variable "node_spot" { type = bool }
variable "deletion_protection" { type = bool }
variable "labels" { type = map(string) }

