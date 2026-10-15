# Conventions

## Annotation language (code comments and relay `.md` files)

- **Declared for this repository: English** (recorded in `.ai/HANDOFF.md`). New code comments and relay `.md` files (`AGENTS.md`, `.ai/`, `docs/`, `README.md`, PRD/spec/decision records) are written in English.
- Existing user-facing messages inside `scripts/diagnose-gcp-auth.sh` and `scripts/install-gcloud-macos.sh` are in Portuguese; leave them unless the user asks to translate them.
- Re-confirm the language for each new task or session unless the user declares it a standing preference.

## Observed conventions

### Terraform

- File layout per module: `main.tf`, `variables.tf`, `outputs.tf`; roots add `versions.tf`, `terraform.tfvars`, `outputs.tf`, and environment-specific files (for example `load-balancer.tf`).
- Naming: `snake_case` for variables and outputs; resource names use a `${var.name}` prefix with a descriptive suffix (`${var.name}-vpc`, `${var.name}-nodes`, `${var.name}-nat`).
- Modules receive already-resolved inputs (IDs/names) from the root, not module outputs of other modules directly.
- Resources are labeled with a `labels` map: `environment`, `managed_by`, `project`; clusters set `resource_labels`.
- The Google provider version is pinned per root via `required_providers`; `required_version >= 1.6.0`.
- `terraform fmt` formatting is applied (history includes a "Format Terraform configuration" commit).
- Organization modules carry comments mapping the GCP resource to its AWS conceptual equivalent (folder ≈ OU, project ≈ account, org policy ≈ SCP).
- Variable validation is used for security invariants, e.g. refusing `0.0.0.0/0` in `master_authorized_networks`.

### Kubernetes

- Manifests are grouped into a single YAML document (single file per workload) with `---` separators; the namespace alone lives in `kubernetes/base/namespace.yaml`.
- Workload namespace: `lab-workloads`; labels use the `app.kubernetes.io/*` convention and `app.kubernetes.io/part-of: multi-cloud-kubernetes-lab`.
- Containers are hardened: `runAsNonRoot`, dropped capabilities, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem` with `emptyDir` mounts, `seccompProfile: RuntimeDefault`, `automountServiceAccountToken: false`, resource requests/limits, and readiness/liveness probes.

### Load balancing, TLS, and edge security

- External L7 traffic is terminated by a **Terraform-owned global external Application Load Balancer** (`environments/lab/load-balancer.tf`), not by a Kubernetes Ingress. Use `load_balancing_scheme = "EXTERNAL_MANAGED"` for the backend service and forwarding rules.
- The GKE workload is exposed through a **standalone NEG** created by the Service `cloud.google.com/neg` annotation with a fixed `name`; Terraform references the NEG self-link. Keep the manifest NEG name and `var.neg_name` identical.
- A global static IP is reserved once (`hello-world-ip`) and shared by the HTTP (80, redirect) and HTTPS (443) forwarding rules.
- Always add an HTTP-to-HTTPS redirect URL map plus a target HTTP proxy; do not serve plaintext.
- TLS uses **Certificate Manager**: a Google-managed certificate authorized via DNS authorization, published in a certificate map and attached to the target HTTPS proxy through `certificate_map`. No certificate material is stored in the repository.
- Edge protection uses a **Cloud Armor** security policy attached to the backend service, with an explicit default rule and least-permissive specific rules.
- The load-balancer health-check ranges `130.211.0.0/22` and `35.191.0.0/16` must reach the pod port, so a dedicated firewall rule targets the GKE node network tag.
- The load balancer depends on the app's NEG, so the environment applies in two phases; document the order and keep `enable_application_load_balancer` in mind.

### Bash scripts

- Shebang `#!/usr/bin/env bash` with `set -Eeuo pipefail` (the public-safety check uses `set -euo pipefail`).
- Shared helpers named `log`, `warn`, and `fail`; `fail` writes to stderr and exits non-zero.

### Security and hygiene

- `.gitignore` excludes `.terraform/`, `*.tfstate*`, `*.tfplan`, all `*.tfvars` except the two environment files, private keys/certs, and `kubeconfig*`.
- `scripts/check-public-safety.sh` enforces the committed-tfvars allowlist and blocks key/cert/state files, credential-like patterns, and nested Git repositories.

## AWS equivalence map (porting reference)

Use this when porting AWS Kubernetes/LB designs. Preserve intent, not product names (`cloud-port` workflow).

| AWS | Google Cloud |
| --- | --- |
| EKS | GKE (config do repo: **Standard**, análogo a EKS + managed node group) |
| Node group / EC2 workers | GKE node pool on Compute Engine |
| Application Load Balancer (ALB) | Global external Application Load Balancer |
| ALB listener | Forwarding rule + target proxy |
| ALB listener rules | URL map |
| Target group (IP target type) | **NEG** |
| Target group + health check + backend | Backend Service |
| Target group health check | Backend Service health check |
| AWS Load Balancer Controller | GKE Ingress/Gateway controller, or Terraform (this repo) |
| ACM certificate | Certificate Manager (or classic Google-managed cert) |
| Security group on the LB | Cloud Armor (no security groups on GCP LBs) |
| Route 53 | Cloud DNS |
| IRSA | Workload Identity Federation for GKE |
| AWS VPC CNI | GKE VPC-native (alias IPs) |
| NAT Gateway | Cloud Router + Cloud NAT |

## Recommended conventions

- Keep the Google provider versions aligned across roots (`bootstrap/state`, `environments/lab`, `environments/organization`) to avoid drift.
- Keep decision records in simple mode (inline in `.ai/DECISIONS.md`) unless the log grows past roughly 15–20 active records.
- Document meaningful architectural choices in `.ai/DECISIONS.md` and reusable findings in `.ai/LEARNINGS.md`.
- Do not add cloud, IaC, Kubernetes, or CI/CD conventions not already established here without recording the decision.
