variable "project_id" {
  description = "Project ID where the Cloud Armor security policy is created."
  type        = string
}

variable "policy_name" {
  description = "Name of the Cloud Armor (backend) security policy."
  type        = string
}

variable "description" {
  description = "Human-readable description of the policy."
  type        = string
  default     = "Baseline Cloud Armor policy: rate limiting + preconfigured WAF rules."
}

variable "enforce" {
  description = "When true, WAF and geo rules are enforced (action=deny). When false they run in preview mode (log only) so you can tune before enforcing."
  type        = bool
  default     = false
}

variable "enable_adaptive_protection" {
  description = "Enable Adaptive Protection Layer 7 DDoS detection."
  type        = bool
  default     = true
}

variable "rate_limit_threshold_count" {
  description = "Number of requests per interval from a single client IP before throttling."
  type        = number
  default     = 100
}

variable "rate_limit_interval_sec" {
  description = "Rate-limit sampling interval in seconds."
  type        = number
  default     = 60
}

variable "rate_limit_ban_duration_sec" {
  description = "How long (seconds) to ban a client IP that exceeds the rate limit."
  type        = number
  default     = 300
}

variable "waf_sensitivity" {
  description = "Preconfigured WAF rule sensitivity level (1-4) for the OWASP CRS rule sets."
  type        = number
  default     = 1

  validation {
    condition     = var.waf_sensitivity >= 1 && var.waf_sensitivity <= 4
    error_message = "waf_sensitivity must be between 1 and 4."
  }
}

variable "blocked_country_codes" {
  description = "Optional list of ISO 3166-1 alpha-2 country codes to block via geo-restriction. Empty disables the geo rule."
  type        = list(string)
  default     = []
}

variable "allowlisted_ip_ranges" {
  description = "Optional list of trusted CIDR ranges that are always allowed (e.g. corporate egress)."
  type        = list(string)
  default     = []
}
