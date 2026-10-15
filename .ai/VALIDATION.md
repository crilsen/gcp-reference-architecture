# Validation

## Completion rule

Before completion, run all applicable project validations that are available and safe. Report each as **Validated**, **Partially validated**, or **Not validated**, with the reason for anything not run. Never claim validation that did not occur.

## Environment note

As of the last context update, `terraform`, `tofu`, `tflint`, `shellcheck`, `helm`, and `gcloud` were **not installed** in the working environment; `kubectl` and `docker` were available. Terraform formatting/validation cannot be run here without installing Terraform.

## Terraform

1. Format check: `terraform fmt -check -recursive` (run from the repository root; fix with `terraform fmt -recursive`).
2. Initialize and validate each root separately (each has its own backend/provider context):
   - `terraform -chdir=bootstrap/state init && terraform -chdir=bootstrap/state validate`
   - `terraform -chdir=environments/lab init && terraform -chdir=environments/lab validate`
   - `terraform -chdir=environments/organization init && terraform -chdir=environments/organization validate`
3. `plan` only with credentials, an initialized backend, and permission; never `apply`/`destroy` without explicit authorization.
4. `tflint` when configured.

## Kubernetes

1. Validate YAML (for example `kubectl apply --dry-run=client -f kubernetes/hello-world/hello-world.yaml`) when a cluster context is available.
2. Prefer client-side dry-run; never `kubectl apply`/`delete` against a real cluster without authorization.

## Scripts

1. Syntax check: `bash -n scripts/*.sh`.
2. `shellcheck scripts/*.sh` when available.
3. Public-safety scan (also run by CI): `bash scripts/check-public-safety.sh`.

## CI

`.github/workflows/public-safety.yml` runs `scripts/check-public-safety.sh` on push and pull request. Reproduce it locally with `bash scripts/check-public-safety.sh`.

## Annotation language

1. Confirm the annotation language was recorded in `.ai/HANDOFF.md` (`Annotation language: English`).
2. Verify new code comments and relay `.md` files use English.
