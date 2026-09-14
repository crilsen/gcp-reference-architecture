project_id         = "gcp-referente-architeture"
gcp_region         = "us-east1"
gcp_zone           = "us-east1-b"
project_name       = "kubernetes-lab"
kubernetes_version = "1.36"

network_cidr     = "10.62.0.0/20"
pod_cidr         = "10.63.0.0/16"
service_cidr     = "10.64.0.0/20"
master_ipv4_cidr = "172.16.0.0/28"

# Replace this documentation-only address with your current public IPv4/32.
master_authorized_networks = [
  { cidr_block = "179.222.235.62/32", display_name = "administrator" }
]

# One zonal e2-standard-2 node is deliberately small for the 90-day trial.
node_machine_type   = "e2-standard-2"
node_disk_size_gb   = 30
node_min_count      = 1
node_max_count      = 2
node_spot           = false
deletion_protection = false
