variable "project_id" {
  description = "Globally unique project ID for this environment (e.g. acme-platform-staging)."
  type        = string
}

variable "project_name" {
  description = "Display name for the project."
  type        = string
  default     = "ACME Platform staging"
}

variable "folder_id" {
  description = "Numeric folder ID to create the project under. Set folder_id OR org_id, not both."
  type        = string
  default     = null
}

variable "org_id" {
  description = "Numeric organization ID to create the project under. Set folder_id OR org_id, not both."
  type        = string
  default     = null
}

variable "billing_account" {
  description = "Billing account ID (XXXXXX-XXXXXX-XXXXXX)."
  type        = string
}

variable "region" {
  description = "Primary region for this environment."
  type        = string
  default     = "europe-west1"
}

variable "alert_email" {
  description = "Email address for the monitoring notification channel. Null disables email alerts."
  type        = string
  default     = null
}

variable "log_sink_destination" {
  description = "Destination for the aggregated log sink (API form). Null disables the sink."
  type        = string
  default     = null
}

# --- Sizing / posture knobs (staging mirrors prod topology at reduced scale) ---

variable "enable_private_endpoint" {
  description = "Whether the GKE control plane endpoint is private-only."
  type        = bool
  default     = true # staging validates the private-endpoint access path
}

variable "master_authorized_networks" {
  description = "CIDR blocks allowed to reach the GKE control plane."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "deletion_protection" {
  description = "Prevent Terraform from deleting the GKE cluster."
  type        = bool
  default     = true
}

variable "cloud_armor_enforce" {
  description = "Enforce Cloud Armor WAF/geo rules (true) or run in preview mode (false)."
  type        = bool
  default     = true # staging enforces so prod behaviour is validated before release
}

variable "blocked_country_codes" {
  description = "ISO country codes to geo-block via Cloud Armor."
  type        = list(string)
  default     = []
}
