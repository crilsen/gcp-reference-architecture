# Session Handoff

## Resume block (read first)

- Repo state: branch `main`, HEAD `f6fe608` plus uncommitted work from this session (see Files Changed); run `git log -1` for the exact tip after committing.
- Source of truth: `AGENTS.md` → `.ai/`
- Budget / usage observed: `unknown`
- Checkpoint updated: `2026-10-15 18:55`
- Last goal: Implement a complete load-balancer edge in Terraform (global external ALB + Cloud Armor + Certificate Manager) and register it as convention.
- Annotation language: `English (standing preference; existing Portuguese strings in scripts/*.sh left as-is)`
- Context update mode: `Automatic`
- Exact next action: `Commit the edge implementation; optionally push. If asked, install Terraform to run fmt/validate and then a real two-phase apply.`
- Blocked by: `None.`
- Resume prompt: `Read AGENTS.md and .ai/HANDOFF.md. Continue from the Resume block. Do not rediscover context.`

## Goal

Make the lab infrastructure complete at the edge: a global external Application Load Balancer, Cloud Armor, and a Certificate Manager certificate, implemented in Terraform and recorded as a convention.

## Current State

Implementation complete and validated as far as the environment allows. Terraform is not installed here, so HCL was not formatted or validated by tooling.

## What Was Done

- Determined that the GKE Ingress API cannot attach Certificate Manager certificate maps; the correct path is a Terraform-owned global external ALB over a GKE standalone NEG.
- `environments/lab/load-balancer.tf`: health check, Cloud Armor policy (default allow, per-IP rate limit with ban, preconfigured SQLi/XSS WAF), backend service (`EXTERNAL_MANAGED`, logging), URL map, modern SSL policy, target HTTPS proxy (certificate map), HTTP->HTTPS redirect, HTTPS and HTTP forwarding rules, and a firewall rule for LB health-check ranges.
- `environments/lab/cert.tf`: Certificate Manager DNS authorization, Google-managed certificate, certificate map and map entry, and optional Cloud DNS A + authorization records.
- `environments/lab/{main,variables,terraform.tfvars,outputs}.tf`: added Certificate Manager and Cloud DNS APIs; new variables (`enable_application_load_balancer`, `enable_cloud_armor`, `armor_rate_limit_count`, `backend_max_rate_per_endpoint`, `neg_name`, `domain_name`, `manage_dns_records`, `dns_managed_zone_name`); outputs (`neg_name`, `certificate_map_name`, `dns_authorization_record`, `cloud_armor_policy_name`).
- `kubernetes/hello-world/hello-world.yaml`: Service now exposes a standalone NEG with a fixed name; removed `BackendConfig`, `Ingress`, and `ManagedCertificate`.
- Updated `kubernetes/hello-world/README.md` (two-phase deploy, DNS, validation) and `README.md` (architecture, created resources, LB section, phase-1 apply).
- Recorded ADR-003 (Terraform-owned ALB), ADR-004 (Certificate Manager), ADR-005 (Cloud Armor); added LB/TLS/edge conventions and an AWS<->GCP equivalence map; learnings L-003 and L-004.

## Files Changed

- `environments/lab/load-balancer.tf` (rewritten), `environments/lab/cert.tf` (new)
- `environments/lab/main.tf`, `variables.tf`, `terraform.tfvars`, `outputs.tf`
- `kubernetes/hello-world/hello-world.yaml`, `kubernetes/hello-world/README.md`
- `README.md`; `.ai/ARCHITECTURE.md`, `.ai/CONVENTIONS.md`, `.ai/DECISIONS.md`, `.ai/LEARNINGS.md`, `.ai/TASKS.md`, `.ai/VALIDATION.md`, `.ai/HANDOFF.md`

## Decisions Made

- ADR-003: Terraform owns the global external ALB; GKE provides only the standalone NEG.
- ADR-004: TLS via Certificate Manager (certificate map on the target HTTPS proxy).
- ADR-005: Cloud Armor attached to the backend service.

## Problems / Risks

- Two-phase apply: the load balancer depends on the app's NEG, so the first apply uses `enable_application_load_balancer = false`.
- The NEG name in the manifest must match `var.neg_name` (`kubernetes-lab-hello-world`).
- Not validated by tooling: Terraform is not installed, so `fmt`/`validate`/`plan` were not run. `plan`/`apply` also require credentials and, for a full plan, the app's NEG.
- `domain_name` is the documentation placeholder; the certificate stays pending until a real domain and the DNS authorization record exist.

## Validation Performed

- Validated: `bash -n scripts/*.sh` (all pass).
- Validated: `bash scripts/check-public-safety.sh` (pass).
- Validated: YAML parse of `kubernetes/hello-world/hello-world.yaml` (4 docs: Namespace, ConfigMap, Deployment, Service) and `kubernetes/base/namespace.yaml`.
- Not validated: `terraform fmt`/`validate`/`plan` (Terraform not installed; `tflint` unavailable).

## Next Actions

1. Commit this work (and optionally push).
2. Run `terraform fmt`/`validate` where Terraform is available, then a real two-phase apply.
