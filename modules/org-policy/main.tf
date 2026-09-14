# AWS conceptual equivalent: Service Control Policy
# GCP implementation: Organization Policy API v2 policy inherited by projects
resource "google_org_policy_policy" "disable_service_account_key_creation" {
  name   = "folders/${var.folder_id}/policies/iam.disableServiceAccountKeyCreation"
  parent = "folders/${var.folder_id}"

  spec {
    rules { enforce = "TRUE" }
  }
}

resource "google_org_policy_policy" "disable_service_account_key_upload" {
  name   = "folders/${var.folder_id}/policies/iam.disableServiceAccountKeyUpload"
  parent = "folders/${var.folder_id}"

  spec {
    rules { enforce = "TRUE" }
  }
}
