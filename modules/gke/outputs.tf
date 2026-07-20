output "cluster_name" {
  description = "The GKE cluster name."
  value       = google_container_cluster.this.name
}

output "cluster_id" {
  description = "The fully-qualified GKE cluster ID."
  value       = google_container_cluster.this.id
}

output "endpoint" {
  description = "The (private) IP address of the cluster control plane endpoint."
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "ca_certificate" {
  description = "Base64-encoded public CA certificate of the cluster."
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "workload_identity_pool" {
  description = "The Workload Identity pool for the cluster."
  value       = local.workload_pool
}

output "node_pool_names" {
  description = "Names of the managed node pools."
  value       = keys(google_container_node_pool.this)
}
