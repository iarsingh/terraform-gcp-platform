output "notification_channel_ids" {
  description = "All notification channel IDs used by the alert policies (provided + created)."
  value       = local.alert_channels
}

output "log_sink_writer_identity" {
  description = "Writer identity of the aggregated log sink (grant it access on the destination). Null if no sink."
  value       = var.log_sink_destination != null ? google_logging_project_sink.this[0].writer_identity : null
}

output "log_based_metric_name" {
  description = "Name of the container error log-based metric."
  value       = google_logging_metric.container_errors.name
}

output "alert_policy_names" {
  description = "Display names of the created alert policies."
  value = compact([
    var.alert_enabled ? google_monitoring_alert_policy.node_cpu[0].display_name : "",
    var.alert_enabled ? google_monitoring_alert_policy.pod_restarts[0].display_name : "",
    var.alert_enabled ? google_monitoring_alert_policy.nat_port_exhaustion[0].display_name : "",
  ])
}
