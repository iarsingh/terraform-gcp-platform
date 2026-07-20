output "project_id" {
  description = "The environment's project ID."
  value       = module.project.project_id
}

output "network_self_link" {
  description = "The Shared VPC self link."
  value       = module.network.network_self_link
}

output "subnets" {
  description = "Subnet details for the environment."
  value       = module.network.subnets
}

output "gke_cluster_name" {
  description = "The GKE cluster name."
  value       = module.gke.cluster_name
}

output "gke_workload_identity_pool" {
  description = "Workload Identity pool for the cluster."
  value       = module.gke.workload_identity_pool
}

output "artifact_registry_repositories" {
  description = "Artifact Registry repositories created for the environment."
  value       = module.artifact_registry.repositories
}

output "cloud_armor_policy_name" {
  description = "Cloud Armor security policy name."
  value       = module.cloud_armor.policy_name
}

output "gke_node_service_account" {
  description = "Least-privilege GKE node service account email."
  value       = module.iam.gke_node_sa_email
}
