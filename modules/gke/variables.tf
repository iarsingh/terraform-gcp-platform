variable "project_id" {
  description = "Project ID where the GKE cluster is created."
  type        = string
}

variable "name" {
  description = "Name of the GKE cluster."
  type        = string
}

variable "region" {
  description = "Region for a regional cluster (control plane replicated across zones in the region)."
  type        = string
}

variable "node_locations" {
  description = "Optional explicit list of zones for node pools. Empty lets GKE spread across the region's zones."
  type        = list(string)
  default     = []
}

variable "network" {
  description = "Self link or name of the VPC network."
  type        = string
}

variable "subnetwork" {
  description = "Self link or name of the subnetwork hosting the nodes."
  type        = string
}

variable "pods_range_name" {
  description = "Name of the subnet secondary range used for pod IPs."
  type        = string
}

variable "services_range_name" {
  description = "Name of the subnet secondary range used for service IPs."
  type        = string
}

variable "node_service_account" {
  description = "Email of the least-privilege service account attached to nodes."
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "The /28 CIDR for the private control plane endpoint. Must not overlap any subnet range."
  type        = string
  default     = "172.16.0.0/28"
}

variable "enable_private_endpoint" {
  description = "When true the control plane has no public endpoint; access is via authorized private networks only."
  type        = bool
  default     = true
}

variable "master_authorized_networks" {
  description = "CIDR blocks allowed to reach the control plane endpoint."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "release_channel" {
  description = "GKE release channel: RAPID, REGULAR, or STABLE."
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "release_channel must be RAPID, REGULAR, or STABLE."
  }
}

variable "deletion_protection" {
  description = "Prevent Terraform from destroying the cluster. Enable in production."
  type        = bool
  default     = true
}

variable "maintenance_start_time" {
  description = "Daily maintenance window start time in RFC3339 HH:MM format (UTC)."
  type        = string
  default     = "02:00"
}

variable "node_pools" {
  description = "Node pools to create for the cluster."
  type = map(object({
    machine_type    = optional(string, "e2-standard-4")
    disk_size_gb    = optional(number, 100)
    disk_type       = optional(string, "pd-balanced")
    image_type      = optional(string, "COS_CONTAINERD")
    min_node_count  = optional(number, 1)
    max_node_count  = optional(number, 3)
    spot            = optional(bool, false)
    max_surge       = optional(number, 1)
    max_unavailable = optional(number, 0)
    labels          = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    tags = optional(list(string), [])
  }))
}

variable "resource_labels" {
  description = "Labels applied to the cluster and its GCE resources."
  type        = map(string)
  default     = {}
}
