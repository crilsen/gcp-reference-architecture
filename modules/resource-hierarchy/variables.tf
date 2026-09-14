variable "organization_id" {
  type      = string
  sensitive = true
}
variable "billing_account_id" {
  type      = string
  sensitive = true
}
variable "folder_name" { type = string }
variable "lab_project_id" { type = string }
variable "production_project_id" { type = string }
