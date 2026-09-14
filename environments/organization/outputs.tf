output "resource_structure" {
  value = {
    management_project = var.management_project_id
    lab_project        = module.hierarchy.lab_project_id
    production_project = module.hierarchy.production_project_id
  }
  sensitive = true
}
output "workloads_folder_id" { value = module.hierarchy.folder_id }
