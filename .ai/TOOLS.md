# Tools

The rules behind these lists live in `.ai/GUARDRAILS.md`. Never store secrets in this file.

## Current availability

Project tooling and command wrappers observed:

- **Terraform** (`>= 1.6.0`) — required to work with the `.tf` roots. Not installed in the last observed working environment.
- **Google Cloud CLI (`gcloud`)** — used for auth and cluster credentials; see `scripts/diagnose-gcp-auth.sh` and `scripts/install-gcloud-macos.sh`.
- **kubectl** — used to reach the GKE cluster; available in the last observed environment.
- **Docker** — implied by the Docker Artifact Registry repository and container images.
- **Bash** — scripts under `scripts/`.
- **GitHub Actions** — `.github/workflows/public-safety.yml`.

Authentication requirements: Google Cloud credentials (ADC / `gcloud auth`) are required for any `plan`/`apply`. Details are not stored here.

## Allowed without additional authorization

- Read and search repository files.
- Make scoped, task-related edits.
- `terraform fmt` / `terraform fmt -check -recursive`.
- `terraform validate` (per root, after `init`).
- `bash -n scripts/*.sh`, `shellcheck` when available, and `bash scripts/check-public-safety.sh` (also the CI check).
- `kubectl apply --dry-run=client` and other read-only `kubectl` commands against an authorized context.
- Update this portable context.

## Requires explicit authorization

- `terraform apply`, `terraform destroy` (any root), including `environments/lab` and `bootstrap/state`.
- `kubectl apply`, `kubectl delete`, or any real-cluster mutation.
- Secret changes, destructive state operations, paid-resource creation (for example the external load balancer, Cloud NAT, or Compute Engine instances), or any external operation with material impact.

## MCP servers and external tools

| Tool or MCP server | Purpose | Allowed | Restricted |
| --- | --- | --- | --- |
| — (none recorded) | — | — | — |

MCP servers are configured by the harness, not by this repository. Record them here when added; do not record endpoints, tokens, or credentials.

## Technology-specific guidance

| Technology | Usually safe | Restricted |
| --- | --- | --- |
| Terraform | `fmt`, `validate`, `plan` (with credentials) | `apply`, `destroy` |
| Kubernetes | `get`, `describe`, `diff`, client dry-run | real-cluster apply/delete |
| Bash scripts | `bash -n`, `shellcheck`, `check-public-safety.sh` | scripts that mutate cloud resources |
| Docker | build/tag locally | pushing to Artifact Registry without authorization |

Before running a command, confirm it is appropriate for the repository and does not require unavailable credentials or mutate external systems.
