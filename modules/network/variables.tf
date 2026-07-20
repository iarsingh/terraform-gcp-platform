variable "project_id" {
  description = "Project ID that hosts the Shared VPC (the host project)."
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network."
  type        = string
}

variable "routing_mode" {
  description = "Network-wide routing mode: REGIONAL or GLOBAL."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "routing_mode must be REGIONAL or GLOBAL."
  }
}

variable "enable_shared_vpc_host" {
  description = "Whether to enable this project as a Shared VPC host project."
  type        = bool
  default     = true
}

variable "region" {
  description = "Primary region for the Cloud Router and Cloud NAT."
  type        = string
}

variable "subnets" {
  description = "Subnets to create. Mark private=true to enable Private Google Access and route egress via Cloud NAT."
  type = list(object({
    name          = string
    ip_cidr_range = string
    region        = string
    private       = bool
    secondary_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
  }))

  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet must be defined."
  }
}

variable "nat_min_ports_per_vm" {
  description = "Minimum number of NAT ports allocated per VM. Raise to reduce the risk of port exhaustion under high egress fan-out."
  type        = number
  default     = 64
}

variable "nat_log_config" {
  description = "Cloud NAT logging filter: ERRORS_ONLY, TRANSLATIONS_ONLY, or ALL."
  type        = string
  default     = "ERRORS_ONLY"

  validation {
    condition     = contains(["ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"], var.nat_log_config)
    error_message = "nat_log_config must be ERRORS_ONLY, TRANSLATIONS_ONLY, or ALL."
  }
}

variable "internal_ranges" {
  description = "CIDR ranges considered internal/trusted for the allow-internal firewall rule."
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}
