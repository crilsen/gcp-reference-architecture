variable "organization_id" {
  description = "Existing Google Cloud organization ID."
  type        = string
  sensitive   = true
}
variable "billing_account_id" {
  description = "Billing account associated with member projects."
  type        = string
  sensitive   = true
}
variable "management_project_id" {
  description = "Existing project used to run governance Terraform."
  type        = string
  sensitive   = true
}
variable "folder_name" { type = string }
variable "lab_project_id" { type = string }
variable "production_project_id" { type = string }
