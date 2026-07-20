variable "project_id" {
  description = "Globally unique GCP project ID (e.g. acme-platform-dev). Must be 6-30 chars, lowercase, digits and hyphens."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a letter, and contain only lowercase letters, digits and hyphens."
  }
}

variable "project_name" {
  description = "Human-readable display name for the project."
  type        = string
}

variable "org_id" {
  description = "Numeric organization ID to create the project under. Mutually exclusive with folder_id."
  type        = string
  default     = null
}

variable "folder_id" {
  description = "Numeric folder ID (folders/1234567890 or 1234567890) to create the project under. Mutually exclusive with org_id."
  type        = string
  default     = null
}

variable "billing_account" {
  description = "Billing account ID (XXXXXX-XXXXXX-XXXXXX) to associate with the project."
  type        = string
}

variable "auto_create_network" {
  description = "Whether GCP should auto-create the default network. Should always be false for a landing zone."
  type        = bool
  default     = false
}

variable "activate_apis" {
  description = "List of Google Cloud APIs to enable on the project."
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "secretmanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

variable "disable_services_on_destroy" {
  description = "Whether to disable the APIs when the project_service resource is destroyed. Keep false to avoid dependency-order destroy failures."
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels applied to the project (e.g. env, team, cost-center)."
  type        = map(string)
  default     = {}
}
