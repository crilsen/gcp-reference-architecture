output "policy_names" {
  value = [google_org_policy_policy.disable_service_account_key_creation.name, google_org_policy_policy.disable_service_account_key_upload.name]
}
