provider "google" { project = var.management_project_id }

module "hierarchy" {
  source = "../../modules/resource-hierarchy"
  organization_id       = var.organization_id
  billing_account_id    = var.billing_account_id
  folder_name           = var.folder_name
  lab_project_id        = var.lab_project_id
  production_project_id = var.production_project_id
}

module "organization_policy" {
  source    = "../../modules/org-policy"
  folder_id = module.hierarchy.folder_id
}
