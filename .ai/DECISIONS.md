# Decision Records

Durable, meaningful choices. Two types:

- **ADR** — architecture decision: how the system is structured.
- **TDR** — technology decision: stack, library, provider, protocol, or tooling.

Status lifecycle: `Proposed → Accepted → Superseded | Deprecated`. ADR and TDR use separate ID sequences.

## Modes

**Mode for this repository: simple (default).** Entries live inline in this file.

- **Simple (default):** entries live inline in this file. Best for small projects and up to roughly 15–20 active records.
- **Scale:** one file per record under `docs/decisions/`, named `ADR-NNN-<slug>.md` or `TDR-NNN-<slug>.md`. This file stays as the index only.

## Entry format

```text
## ADR-NNN / TDR-NNN — Title
Type: ADR | TDR
Status: Proposed | Accepted | Superseded | Deprecated
Date: YYYY-MM-DD
Owners: <who>
Supersedes: <ID or none>

Context:
...

Decision:
...

Reasoning:
...

Consequences:
...
```

## Index

| ID | Type | Title | Status | Date | File |
| --- | --- | --- | --- | --- | --- |
| TDR-001 | TDR | Google Cloud, Terraform, and GCS remote state | Accepted | 2026-10-15 | inline |
| ADR-001 | ADR | GKE Standard on Compute Engine (not Autopilot) | Accepted | 2026-10-15 | inline |
| ADR-002 | ADR | Private VPC-native cluster with restricted endpoint and Cloud NAT egress | Accepted | 2026-10-15 | inline |
| ADR-003 | ADR | Terraform-owned global external Application Load Balancer over a GKE standalone NEG | Accepted | 2026-10-15 | inline |
| ADR-004 | ADR | Certificate Manager for TLS termination | Accepted | 2026-10-15 | inline |
| ADR-005 | ADR | Cloud Armor on the external load balancer | Accepted | 2026-10-15 | inline |

## Records

These entries are recorded as **observed** from the initial code and `README.md`, not invented. Dates are the date the record was created.

## TDR-001 — Google Cloud, Terraform, and GCS remote state
Type: TDR
Status: Accepted
Date: 2026-10-15
Owners: repository maintainers
Supersedes: none

Context:
The repository is a Google Cloud reference architecture. It needs reproducible infrastructure and a durable remote state backend.

Decision:
Use Google Cloud only, managed with Terraform (`hashicorp/google`, `terraform >= 1.6.0`), with remote state stored in a private, versioned GCS bucket created by `bootstrap/state`.

Reasoning:
Terraform is the standard IaC tool for GCP; the bootstrap root avoids a circular dependency where a backend bucket is needed before it can be created.

Consequences:
Each root initializes its own backend/provider context. The bootstrap state stays local and must be backed up. Evidence: `bootstrap/state/`, `environments/lab/versions.tf`.

## ADR-001 — GKE Standard on Compute Engine (not Autopilot)
Type: ADR
Status: Accepted
Date: 2026-10-15
Owners: repository maintainers
Supersedes: none

Context:
The reference must mirror "EKS with EC2 worker nodes".

Decision:
Use a private GKE **Standard** cluster with a separately managed, autoscaling Compute Engine node pool (`e2-standard-2` by default). Not Autopilot and not `kubeadm`.

Reasoning:
Standard mode keeps node-level control analogous to EC2 worker nodes, matching the multi-cloud Kubernetes lab intent.

Consequences:
Nodes, disks, and autoscaling are the operator's responsibility and cost. Evidence: `modules/gke/main.tf`, `README.md`.

## ADR-002 — Private VPC-native cluster with restricted endpoint and Cloud NAT egress
Type: ADR
Status: Accepted
Date: 2026-10-15
Owners: repository maintainers
Supersedes: none

Context:
Nodes should not be publicly reachable, yet must reach the Internet, and the control-plane endpoint must not be open to the world.

Decision:
VPC-native private nodes (`enable_private_nodes = true`) with Pod/Service alias ranges, a public control-plane endpoint restricted to `master_authorized_networks` (a `/32` allowlist that rejects `0.0.0.0/0`), and outbound egress via Cloud Router + Public Cloud NAT.

Reasoning:
Private nodes plus NAT remove public node IPs while preserving outbound access; the endpoint allowlist limits API exposure.

Consequences:
Administrators must maintain the allowlist as their public IP changes. Evidence: `modules/gke/main.tf`, `modules/network/main.tf`, `environments/lab/variables.tf`.

## ADR-003 — Terraform-owned global external Application Load Balancer over a GKE standalone NEG
Type: ADR
Status: Accepted
Date: 2026-10-15
Owners: repository maintainers
Supersedes: none

Context:
The demo workload needs an L7 external load balancer with WAF and a managed certificate. GKE Ingress can create the load balancer, but it is opinionated and cannot attach Certificate Manager certificate maps.

Decision:
Own the global external Application Load Balancer in Terraform (`environments/lab/load-balancer.tf`): health check, backend service, URL map, target HTTP/HTTPS proxies, and forwarding rules (80 redirect and 443). The backend is the GKE **standalone NEG** created from the Service `cloud.google.com/neg` annotation with a fixed name; Terraform references the NEG self-link directly. The Kubernetes Ingress, BackendConfig, and ManagedCertificate were removed.

Reasoning:
Terraform ownership gives explicit control over every load-balancer object and is the only path that supports Certificate Manager certificate maps and Cloud Armor directly. A fixed NEG name keeps the reference deterministic.

Consequences:
Because the NEG exists only after the Service is applied, the lab applies in two phases (`enable_application_load_balancer = false`, deploy the app, then `true`). The NEG name in `kubernetes/hello-world/hello-world.yaml` must match `var.neg_name`. Evidence: `environments/lab/load-balancer.tf`.

## ADR-004 — Certificate Manager for TLS termination
Type: ADR
Status: Accepted
Date: 2026-10-15
Owners: repository maintainers
Supersedes: none

Context:
TLS must be provisioned and rotated without storing certificate material in the repository.

Decision:
Use Google Cloud Certificate Manager: a Google-managed certificate authorized through a DNS authorization, published in a certificate map, and attached to the global HTTPS target proxy (`environments/lab/cert.tf`).

Reasoning:
Certificate Manager is Google Cloud's managed certificate service, automates issuance and renewal, and avoids private-key handling. Certificate maps are supported by global external Application Load Balancers.

Consequences:
A DNS TXT/CNAME authorization record must exist before the certificate becomes active; the value is exposed as the `dns_authorization_record` output. DNS can be managed manually or by Cloud DNS when `manage_dns_records = true`. Evidence: `environments/lab/cert.tf`.

## ADR-005 — Cloud Armor on the external load balancer
Type: ADR
Status: Accepted
Date: 2026-10-15
Owners: repository maintainers
Supersedes: none

Context:
The public application needs edge protection against abuse and common web attacks.

Decision:
Attach a Cloud Armor security policy to the backend service: per-IP rate limiting with a temporary ban, and preconfigured SQLi/XSS WAF rules, on top of a default allow. Token-tunable thresholds live in `terraform.tfvars`.

Reasoning:
Cloud Armor is the native GCP L7 edge security control and integrates directly with the global external Application Load Balancer backend service.

Consequences:
Policy changes are Terraform-managed and reviewable; blocked requests return `403`/`429` and can be observed in Cloud Logging. Evidence: `environments/lab/load-balancer.tf`.

Do not backfill invented history. Record decisions that are observed, expressly documented, or approved during future work.
