output "bucket_name" {
  value = google_storage_bucket.terraform_state.name
}

output "lab_backend_init_command" {
  value = "terraform -chdir=gcp/environments/lab init -migrate-state -backend-config=bucket=${google_storage_bucket.terraform_state.name} -backend-config=prefix=environments/lab"
}
