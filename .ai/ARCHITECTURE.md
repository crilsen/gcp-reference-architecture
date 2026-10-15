# Architecture

## Overview

The repository deploys the Google Cloud equivalent of "EKS with EC2 worker nodes": Google manages the Kubernetes control plane, while a GKE **Standard** node pool runs on configurable Compute Engine VMs. The design is documented at a high level in `README.md`.

```text
Internet
   |
   +-- restricted public GKE API endpoint (/32 allowlist)
   |
Google Cloud VPC (custom mode, regional routing)
   |
   +-- subnet 10.62.0.0/20
       +-- secondary range: Pods 10.63.0.0/16
       +-- secondary range: Services 10.64.0.0/20
       +-- private GKE Standard node pool (Compute Engine)
              |
              +-- Cloud Router -> Cloud NAT -> outbound Internet
```

## Components

- **`modules/network`** — custom-mode VPC (`auto_create_subnetworks = false`, `routing_mode = REGIONAL`), a node subnet with `private_ip_google_access` and Pod/Service alias ranges, VPC Flow Logs, an optional regional Cloud Router + Public Cloud NAT (`enable_cloud_nat`), and firewall rules: internal cluster traffic, IAP SSH (`35.235.240.0/20`), node egress (`0.0.0.0/0`), and a priority-`65534` deny-by-default external ingress rule.
- **`modules/gke`** — a dedicated least-privilege node service account and its project IAM bindings, a private zonal GKE Standard cluster, a separately managed autoscaling node pool, and a regional Docker Artifact Registry repository.
- **`bootstrap/state`** — a GCS bucket for Terraform remote state (object versioning, 7-day soft delete, uniform bucket-level access, enforced public-access prevention, `prevent_destroy`). Its own state is intentionally local to avoid a circular backend dependency.
- **`environments/lab`** — wires `network` + `gke`, enables the required project APIs, and creates a global static IP (`hello-world-ip`) for the Ingress. Uses the GCS backend with prefix `environments/lab`.
- **`environments/organization`** — `modules/resource-hierarchy` (a Resource Manager folder plus lab/production projects, `auto_create_network = false`, `deletion_policy = PREVENT`) and `modules/org-policy` (folder-level policies disabling service-account key creation and upload). Requires an Organization and billing account.
- **`kubernetes/hello-world`** — Namespace `lab-workloads`, ConfigMap, a hardened single-replica nginx Deployment, a `ClusterIP` Service with a NEG annotation, a `BackendConfig`, a GKE Ingress with a global static IP, and a `ManagedCertificate`. `kubernetes/base/namespace.yaml` holds the namespace alone.

## Traffic flow

- **Ingress (workload):** Internet → global static IP → GKE Ingress → NEG → `ClusterIP` Service → Pod. The NEG connects Pods directly to the load-balancer backend, avoiding a second load balancer.
- **Cluster API:** administrator traffic reaches the public control-plane endpoint only from `master_authorized_networks` (a `/32` allowlist; `0.0.0.0/0` is rejected by variable validation).
- **Egress:** nodes have no public IPs and reach the Internet through Cloud Router + Cloud NAT.

## Networking

GCP VPCs install the local subnet route and default Internet route automatically, and VPC-native GKE uses alias IP routes for Pods and Services, so no custom static routes are declared. Cloud Router and Cloud NAT own private-node egress.

## Identity and security

- A dedicated node service account with `roles/artifactregistry.reader`, `roles/logging.logWriter`, `roles/monitoring.metricWriter`, `roles/monitoring.viewer`, and `roles/stackdriver.resourceMetadata.writer`.
- Workload Identity Federation for GKE (`<project>.svc.id.goog`) and `GKE_METADATA` workload metadata.
- Private nodes with shielded nodes and secure boot; node image `COS_CONTAINERD`.
- Organization policies at folder level disabling service-account key creation and upload.
- Public-safety CI scan rejects key/cert/state files, unexpected `.tfvars`, credential-like patterns, and nested Git repositories.

## State management

Remote state is a private, versioned GCS bucket created by `bootstrap/state`; `environments/lab` uses the `gcs` backend with prefix `environments/lab`. `environments/lab` and `bootstrap/state` pin the Google provider to `~> 8.0`; `environments/organization` pins `~> 7.0` (version drift — see `.ai/LEARNINGS.md`).

## Environments

- **lab** — cost-controlled, disposable; zonal cluster with one `e2-standard-2` node autoscaling to two, `deletion_protection = false`.
- **organization** — governance boundary for protected workload projects; separate root.

## CI/CD

Single workflow, `.github/workflows/public-safety.yml`: checkout, then `bash scripts/check-public-safety.sh`. No plan/apply pipeline is present.

## Unknown / not determined from repository

- Runtime components and integrations beyond the hello-world demo.
- Observability configuration beyond the cluster's built-in Logging/Monitoring/managed Prometheus settings.
- Production availability and recovery model (README notes the single-zone lab is not highly available).
