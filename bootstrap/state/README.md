# Terraform state bootstrap

This root creates the private GCS bucket used by the workload Terraform backend.
It intentionally keeps its own small bootstrap state locally, avoiding a circular
dependency in which Terraform needs a backend bucket before it can create one.

Choose a globally unique bucket name and apply:

```bash
terraform -chdir=gcp/bootstrap/state init
terraform -chdir=gcp/bootstrap/state apply \
  -var='project_id=YOUR_PROJECT_ID' \
  -var='bucket_name=YOUR_GLOBALLY_UNIQUE_TFSTATE_BUCKET'
```

The bucket uses object versioning, seven-day soft delete, uniform bucket-level
access, enforced public-access prevention, and Terraform deletion protection.
Keep the bootstrap `terraform.tfstate` file private and backed up.

For an existing local Lab state, migrate it rather than running a fresh init:

```bash
terraform -chdir=gcp/environments/lab init -migrate-state \
  -backend-config='bucket=YOUR_GLOBALLY_UNIQUE_TFSTATE_BUCKET' \
  -backend-config='prefix=environments/lab'
```

Confirm the migration before deleting any local state backup:

```bash
terraform -chdir=gcp/environments/lab state list
terraform -chdir=gcp/environments/lab plan
gcloud storage ls gs://YOUR_GLOBALLY_UNIQUE_TFSTATE_BUCKET/environments/lab/
```
