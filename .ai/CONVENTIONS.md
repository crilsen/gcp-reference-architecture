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

### Bash scripts

- Shebang `#!/usr/bin/env bash` with `set -Eeuo pipefail` (the public-safety check uses `set -euo pipefail`).
- Shared helpers named `log`, `warn`, and `fail`; `fail` writes to stderr and exits non-zero.

### Security and hygiene

- `.gitignore` excludes `.terraform/`, `*.tfstate*`, `*.tfplan`, all `*.tfvars` except the two environment files, private keys/certs, and `kubeconfig*`.
- `scripts/check-public-safety.sh` enforces the committed-tfvars allowlist and blocks key/cert/state files, credential-like patterns, and nested Git repositories.

## Recommended conventions

- Keep the Google provider versions aligned across roots (`bootstrap/state`, `environments/lab`, `environments/organization`) to avoid drift.
- Keep decision records in simple mode (inline in `.ai/DECISIONS.md`) unless the log grows past roughly 15–20 active records.
- Document meaningful architectural choices in `.ai/DECISIONS.md` and reusable findings in `.ai/LEARNINGS.md`.
- Do not add cloud, IaC, Kubernetes, or CI/CD conventions not already established here without recording the decision.
