locals {
  workload_pool = "${var.project_id}.svc.id.goog"
}

resource "google_container_cluster" "this" {
  name     = var.name
  project  = var.project_id
  location = var.region

  network    = var.network
  subnetwork = var.subnetwork

  # Manage node pools explicitly; remove the implicit default pool.
  remove_default_node_pool = true
  initial_node_count       = 1

  node_locations = length(var.node_locations) > 0 ? var.node_locations : null

  # VPC-native (alias IP) cluster using pre-provisioned secondary ranges.
  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Private nodes with no public IPs; control plane endpoint optionally private.
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Workload Identity: pods assume Google service accounts, no node key sharing.
  workload_identity_config {
    workload_pool = local.workload_pool
  }

  # Dataplane V2 (eBPF) provides in-kernel network policy enforcement.
  datapath_provider = "ADVANCED_DATAPATH"

  release_channel {
    channel = var.release_channel
  }

  # Shielded nodes: secure boot + integrity monitoring at the cluster level.
  enable_shielded_nodes = true

  vertical_pod_autoscaling {
    enabled = true
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  # Send control-plane and workload logs/metrics to Cloud Operations, and
  # enable Google Cloud Managed Service for Prometheus.
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_start_time
    }
  }

  resource_labels = var.resource_labels

  deletion_protection = var.deletion_protection

  # Node pools are managed as separate resources; ignore drift in the throwaway
  # default pool bootstrap count.
  lifecycle {
    ignore_changes = [initial_node_count]
  }
}

resource "google_container_node_pool" "this" {
  for_each = var.node_pools

  name     = each.key
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.this.name

  autoscaling {
    min_node_count = each.value.min_node_count
    max_node_count = each.value.max_node_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = each.value.max_surge
    max_unavailable = each.value.max_unavailable
  }

  node_config {
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type
    image_type   = each.value.image_type
    spot         = each.value.spot

    # Attach the least-privilege node SA and rely on IAM (not broad scopes).
    service_account = var.node_service_account
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    labels = each.value.labels
    tags   = each.value.tags

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Restrict access to the node metadata server; required for Workload Identity.
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  lifecycle {
    ignore_changes = [node_config[0].labels]
  }
}
