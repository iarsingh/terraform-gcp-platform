locals {
  created_channels = var.email_notification_address != null ? [google_monitoring_notification_channel.email[0].id] : []
  alert_channels   = concat(var.notification_channels, local.created_channels)
}

# Optional email notification channel used by all alert policies below.
resource "google_monitoring_notification_channel" "email" {
  count = var.email_notification_address != null ? 1 : 0

  project      = var.project_id
  display_name = "${var.name_prefix}-oncall-email"
  type         = "email"
  labels = {
    email_address = var.email_notification_address
  }
}

# Aggregated log sink exporting selected entries to durable storage.
resource "google_logging_project_sink" "this" {
  count = var.log_sink_destination != null ? 1 : 0

  project     = var.project_id
  name        = "${var.name_prefix}-aggregated-sink"
  destination = var.log_sink_destination
  filter      = var.log_sink_filter

  # Grant the sink's writer identity permission on the destination.
  unique_writer_identity = true
}

# Log-based metric counting container error/warning events for trend alerting.
resource "google_logging_metric" "container_errors" {
  project = var.project_id
  name    = "${var.name_prefix}/container_error_count"
  filter  = "resource.type=\"k8s_container\" AND severity>=ERROR"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
    labels {
      key         = "namespace"
      value_type  = "STRING"
      description = "Kubernetes namespace of the erroring container"
    }
  }

  label_extractors = {
    namespace = "EXTRACT(resource.labels.namespace_name)"
  }
}

# --- Alert: sustained high node CPU allocation utilization. ---
resource "google_monitoring_alert_policy" "node_cpu" {
  count = var.alert_enabled ? 1 : 0

  project      = var.project_id
  display_name = "${var.name_prefix} - GKE node CPU high"
  combiner     = "OR"

  conditions {
    display_name = "Node CPU allocatable utilization > ${var.node_cpu_threshold}"
    condition_threshold {
      filter          = "resource.type = \"k8s_node\" AND metric.type = \"kubernetes.io/node/cpu/allocatable_utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.node_cpu_threshold
      duration        = "300s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.alert_channels

  documentation {
    content   = "One or more GKE nodes have sustained CPU utilization above threshold. Check for noisy neighbors, missing requests/limits, or the need to scale the node pool."
    mime_type = "text/markdown"
  }
}

# --- Alert: excessive container restarts (crash loops). ---
resource "google_monitoring_alert_policy" "pod_restarts" {
  count = var.alert_enabled ? 1 : 0

  project      = var.project_id
  display_name = "${var.name_prefix} - Pod restart storm"
  combiner     = "OR"

  conditions {
    display_name = "Container restarts > ${var.pod_restart_threshold} in window"
    condition_threshold {
      filter          = "resource.type = \"k8s_container\" AND metric.type = \"kubernetes.io/container/restart_count\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.pod_restart_threshold
      duration        = "0s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_DELTA"
      }
      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.alert_channels

  documentation {
    content   = "Containers are restarting frequently, indicating crash loops. Inspect pod events, readiness/liveness probes, and recent deployments."
    mime_type = "text/markdown"
  }
}

# --- Alert: Cloud NAT dropping egress packets (port exhaustion). ---
resource "google_monitoring_alert_policy" "nat_port_exhaustion" {
  count = var.alert_enabled ? 1 : 0

  project      = var.project_id
  display_name = "${var.name_prefix} - Cloud NAT port exhaustion"
  combiner     = "OR"

  conditions {
    display_name = "NAT dropped sent packets > ${var.nat_port_usage_threshold}/s"
    condition_threshold {
      filter          = "resource.type = \"nat_gateway\" AND metric.type = \"router.googleapis.com/nat/dropped_sent_packets_count\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.nat_port_usage_threshold
      duration        = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.alert_channels

  documentation {
    content   = "Cloud NAT is dropping egress packets, a strong signal of source-port exhaustion. Increase min_ports_per_vm, add NAT IPs, or reduce per-VM egress fan-out."
    mime_type = "text/markdown"
  }
}
