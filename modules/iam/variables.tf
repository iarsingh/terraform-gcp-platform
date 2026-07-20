variable "project_id" {
  description = "Project ID where service accounts and IAM bindings are created."
  type        = string
}

variable "name_prefix" {
  description = "Prefix applied to created service account IDs (e.g. env name)."
  type        = string
}

variable "node_sa_roles" {
  description = "Project roles granted to the GKE node service account. Keep least-privilege."
  type        = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader",
  ]
}

variable "workload_identity_bindings" {
  description = <<-EOT
    Map of Google service accounts to create and bind to Kubernetes service accounts
    via Workload Identity. Key is a logical name; value describes the KSA to impersonate it.
  EOT
  type = map(object({
    display_name    = string
    namespace       = string
    ksa_name        = string
    project_roles   = optional(list(string), [])
    secret_accessor = optional(bool, false)
  }))
  default = {}
}

variable "workload_identity_pool" {
  description = "Workload Identity pool for the project, typically \"<project_id>.svc.id.goog\". Defaults to the project's pool."
  type        = string
  default     = null
}

variable "custom_role_id" {
  description = "ID for an example least-privilege custom role (letters, digits, underscores, periods)."
  type        = string
  default     = "platformDeployer"
}
