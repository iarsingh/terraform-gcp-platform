output "gke_node_sa_email" {
  description = "Email of the least-privilege GKE node service account."
  value       = google_service_account.gke_node.email
}

output "gke_node_sa_id" {
  description = "Fully-qualified ID of the GKE node service account."
  value       = google_service_account.gke_node.id
}

output "workload_service_accounts" {
  description = "Map of workload logical name to its Google service account email."
  value       = { for k, sa in google_service_account.workload : k => sa.email }
}

output "custom_role_id" {
  description = "Fully-qualified ID of the example custom deployer role."
  value       = google_project_iam_custom_role.platform_deployer.id
}
