variable "project_id" {
  description = "Project ID where logging sinks, metrics, and alert policies are created."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for created monitoring resources (e.g. env name)."
  type        = string
}

variable "log_sink_destination" {
  description = <<-EOT
    Destination for the aggregated log sink, in the API form Cloud Logging expects,
    e.g. "storage.googleapis.com/BUCKET", "bigquery.googleapis.com/projects/P/datasets/D",
    or "logging.googleapis.com/projects/P/locations/L/buckets/B". Null disables the sink.
  EOT
  type        = string
  default     = null
}

variable "log_sink_filter" {
  description = "Advanced log filter selecting which entries the sink exports."
  type        = string
  default     = "severity >= WARNING"
}

variable "notification_channels" {
  description = "Existing Cloud Monitoring notification channel IDs to attach to alert policies."
  type        = list(string)
  default     = []
}

variable "email_notification_address" {
  description = "Optional email address; when set, an email notification channel is created and used by alert policies."
  type        = string
  default     = null
}

variable "node_cpu_threshold" {
  description = "Node CPU allocation utilization (0-1) above which the alert fires."
  type        = number
  default     = 0.85
}

variable "pod_restart_threshold" {
  description = "Container restart count over the alignment window above which the alert fires."
  type        = number
  default     = 5
}

variable "nat_port_usage_threshold" {
  description = "Cloud NAT dropped-sent-packets rate (packets/sec) above which the port-exhaustion alert fires. Any sustained non-zero rate is a strong signal of source-port exhaustion."
  type        = number
  default     = 0
}

variable "alert_enabled" {
  description = "Master switch to enable/disable all alert policies in this module."
  type        = bool
  default     = true
}
