# Learnings

Append-only buffer of reusable, non-obvious learnings captured while working, so future sessions and tools do not rediscover them. This is not task state (`TASKS.md`), not a session handoff (`HANDOFF.md`), and not a durable decision record (`DECISIONS.md`).

## How to use

- Append one entry per learning. Do not rewrite or delete entries; to correct one, mark it `superseded` and add a new entry.
- Capture only learnings that are non-obvious and likely to recur. Skip anything already stated in `CONVENTIONS.md`, `DECISIONS.md`, `TOOLS.md`, or `VALIDATION.md`.
- Keep each entry short and evidence-based. Prefer `observed` facts over speculation.
- This file is a buffer, not a permanent home: promote durable learnings and keep the entry as a breadcrumb.

## Entry format

```text
### L-001 — <short title>
Date: YYYY-MM-DD
Status: active | superseded | promoted
Confidence: observed | inferred
Scope: repo | <path-or-glob> | <technology>
Context: <what was being done>
Evidence: <file:line, command output, or concrete observation>
Pattern / rule: <the reusable takeaway>
Promotion: none | CONVENTIONS.md | DECISIONS.md#ADR-nnn | TOOLS.md | VALIDATION.md
```

## Promotion rules

- Recurring pattern → `CONVENTIONS.md`
- Durable architectural choice → `DECISIONS.md` (ADR), cross-referenced here
- Safe or restricted command rule → `TOOLS.md`
- Completion or validation check → `VALIDATION.md`

After promotion, set the entry to `Status: promoted` and keep it as a breadcrumb; do not duplicate the rule body.

## Compaction

- Keep at most 40 active entries. When exceeded, consolidate related entries, promote what is durable, and mark the rest `superseded`.
- Compaction means summarizing and promoting, not erasing history. Record the compaction in `HANDOFF.md`.

## Entries

### L-001 — Documentation references a non-existent `gcp/` parent directory
Date: 2026-10-15
Status: active
Confidence: observed
Scope: repo
Context: Bootstrapping agent context for the repository.
Evidence: `README.md` uses `terraform -chdir=gcp/bootstrap/state ...` and `cd gcp/environments/lab`; `bootstrap/state/README.md` and `bootstrap/state/outputs.tf` also emit `gcp/...` paths. The repository root already is the project; the `gcp/` directory does not exist.
Pattern / rule: The docs assume the repository was checked out inside a `gcp/` directory. Any command copied from the README must drop the `gcp/` prefix when run from the repository root.
Promotion: none

### L-002 — Google provider version drift across Terraform roots
Date: 2026-10-15
Status: active
Confidence: observed
Scope: **/*.tf
Context: Reviewing Terraform roots during bootstrap.
Evidence: `environments/lab/versions.tf` and `bootstrap/state/versions.tf` pin `google ~> 8.0`; `environments/organization/versions.tf` pins `google ~> 7.0`.
Pattern / rule: The three roots can resolve different provider major versions; keep them aligned to avoid behavioral drift and upgrade surprises.
Promotion: none

### L-003 — GKE Ingress cannot attach Certificate Manager certificate maps
Date: 2026-10-15
Status: promoted
Confidence: observed
Scope: **/*.tf, kubernetes/**
Context: Choosing where to terminate TLS for the global load balancer.
Evidence: GKE docs and community reports: the `ingress.gcp.kubernetes.io/pre-shared-cert` annotation accepts classic self-managed/Google-managed SSL certificates, not Certificate Manager certificate maps; certificate maps are supported by the Gateway API and by target proxies. External source: GKE "Secure traffic for GKE Ingress", kubernetes/ingress-gce issue 1692.
Pattern / rule: To use Certificate Manager certificate maps, own the load balancer (Terraform) or use the GKE Gateway API; the classic Ingress API cannot.
Promotion: CONVENTIONS.md (Load balancing, TLS, and edge security)

### L-004 — Standalone NEG forces a two-phase Terraform apply
Date: 2026-10-15
Status: promoted
Confidence: observed
Scope: environments/lab/**
Context: Wiring a Terraform-owned backend service to a GKE NEG.
Evidence: GKE "Container-native load balancing through standalone zonal NEGs": the NEG is created by the NEG controller only after the Service exists, while the Terraform backend service references the NEG.
Pattern / rule: Apply the cluster first, deploy the Service (creating the NEG), then apply the load balancer. A fixed NEG name (`cloud.google.com/neg` `name` field) makes the reference deterministic.
Promotion: CONVENTIONS.md (Load balancing, TLS, and edge security)
