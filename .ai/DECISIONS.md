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

Do not backfill invented history. Record decisions that are observed, expressly documented, or approved during future work.
