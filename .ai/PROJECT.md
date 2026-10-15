# Project

## Identity

- **Name:** gcp-reference-architecture
- **Objective:** Reference implementation of the Google Cloud equivalent of EKS with EC2 worker nodes: a Google-managed GKE Standard control plane plus a Compute Engine node pool. It is not Autopilot and it does not install Kubernetes with `kubeadm`.
- **Repository purpose:** Reusable, self-contained reference architecture with deployable environments and shared Terraform modules.
- **Status:** Infrastructure as code, a demo workload, helper scripts, and one CI workflow are present. There is no production application source code.

## Observed

- Primary technology: **Terraform** (HCL). Plus Kubernetes YAML manifests, Bash scripts, and a GitHub Actions workflow.
- Cloud provider: **Google Cloud only**, via the `hashicorp/google` provider.
- Terraform roots:
  - `bootstrap/state/` — creates the private GCS bucket used as the remote backend (its own state stays local).
  - `environments/lab/` — the deployable GKE Standard lab (the main entry point).
  - `environments/organization/` — resource hierarchy (folder, lab/production projects) and organization policies; requires a Google Cloud Organization.
- Reusable modules: `modules/network`, `modules/gke`, `modules/resource-hierarchy`, `modules/org-policy`.
- Default location: region `us-east1`, zone `us-east1-b`.
- Demo workload: `kubernetes/hello-world/` (nginx), published through a GKE Ingress that provisions an external Application Load Balancer.
- CI: `.github/workflows/public-safety.yml` runs `scripts/check-public-safety.sh` on every push and pull request.
- Versions: `terraform required_version >= 1.6.0`; Google provider `~> 8.0` in `bootstrap/state` and `environments/lab`, and `~> 7.0` in `environments/organization`.

## Unknown / not determined from repository

- Real business workload, target users, and production readiness.
- Cost and scale targets beyond the disposable lab (README treats the lab as a 90-day trial / cost-controlled setup).
- Secret management strategy (no Secret Manager or equivalent configuration found).

## Conventions

- Context belongs to the repository and travels with Git; `.ai/` is the portable source of truth.
- Prefer safe semi-autonomous work: exploration, scoped edits, formatting, linting, and validation are allowed; impactful external operations (`terraform apply`/`destroy`, cluster mutation, paid resources) require explicit approval.
