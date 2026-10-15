# Current Work

## Active

- None.

## Planned

- Keep `.ai/` context current as work happens (automatic mode).
- Resolve documentation path references: `README.md` and `bootstrap/state/README.md` use `gcp/...` paths that do not exist in this repository (the root already is the project). See `.ai/LEARNINGS.md` L-001.
- Align the Google provider version across Terraform roots (see `.ai/LEARNINGS.md` L-002).
- Decide whether to remove Windows `*:Zone.Identifier` metadata files and keep them untracked.

## Blocked

- None.

## Completed

- Plug-and-play bootstrap: populated `.ai/` (PROJECT, ARCHITECTURE, CONVENTIONS, VALIDATION, TOOLS, TASKS, HANDOFF) with observed facts, recorded decisions and learnings, and set automatic update mode with annotation language English.
- Implemented the Terraform-owned global external Application Load Balancer over a GKE standalone NEG, with Cloud Armor and Certificate Manager TLS (`environments/lab/load-balancer.tf`, `cert.tf`); updated the Kubernetes manifest, READMEs, ADR-003/004/005, and conventions.
