output "project_id" {
  description = "The project ID."
  value       = google_project.this.project_id
}

output "project_number" {
  description = "The numeric project number, useful for IAM member strings and service agents."
  value       = google_project.this.number
}

output "enabled_apis" {
  description = "The set of APIs enabled on the project."
  value       = keys(google_project_service.apis)
}
