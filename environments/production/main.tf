locals {
  env         = "production"
  name_prefix = "acme-prod"

  labels = {
    env         = local.env
    managed_by  = "terraform"
    team        = "platform"
    cost_center = "production"
    compliance  = "in-scope"
  }

  private_subnet_name = "${local.name_prefix}-private-${var.region}"
  public_subnet_name  = "${local.name_prefix}-public-${var.region}"
  pods_range_name     = "${local.name_prefix}-pods"
  services_range_name = "${local.name_prefix}-services"
}

module "project" {
  source = "../../modules/project"

  project_id      = var.project_id
  project_name    = var.project_name
  org_id          = var.org_id
  folder_id       = var.folder_id
  billing_account = var.billing_account
  labels          = local.labels
}

module "network" {
  source = "../../modules/network"

  project_id   = module.project.project_id
  network_name = "${local.name_prefix}-vpc"
  region       = var.region

  # production: generous NAT port allocation + full NAT logging for auditing.
  nat_min_ports_per_vm = 256
  nat_log_config       = "ALL"

  subnets = [
    {
      name          = local.public_subnet_name
      ip_cidr_range = "10.12.16.0/24"
      region        = var.region
      private       = false
    },
    {
      name          = local.private_subnet_name
      ip_cidr_range = "10.12.0.0/20"
      region        = var.region
      private       = true
      secondary_ranges = [
        { range_name = local.pods_range_name, ip_cidr_range = "10.22.0.0/16" },
        { range_name = local.services_range_name, ip_cidr_range = "10.32.0.0/20" },
      ]
    },
  ]
}

module "iam" {
  source = "../../modules/iam"

  project_id  = module.project.project_id
  name_prefix = local.name_prefix

  workload_identity_bindings = {
    api = {
      display_name    = "API workload (production)"
      namespace       = "apps"
      ksa_name        = "api"
      project_roles   = ["roles/monitoring.metricWriter"]
      secret_accessor = true
    }
    worker = {
      display_name    = "Async worker workload (production)"
      namespace       = "apps"
      ksa_name        = "worker"
      project_roles   = ["roles/monitoring.metricWriter"]
      secret_accessor = true
    }
  }
}

module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id = module.project.project_id
  location   = var.region

  repositories = {
    "${local.name_prefix}-docker" = {
      format                          = "DOCKER"
      description                     = "Application container images (production)"
      keep_most_recent                = 50
      delete_untagged_older_than_days = 60
      immutable_tags                  = true # prod images are immutable for provenance
    }
  }

  reader_members = ["serviceAccount:${module.iam.gke_node_sa_email}"]
}

module "gke" {
  source = "../../modules/gke"

  project_id = module.project.project_id
  name       = "${local.name_prefix}-gke"
  region     = var.region

  # Explicit multi-zone node placement for high availability.
  node_locations = var.node_locations

  network             = module.network.network_self_link
  subnetwork          = module.network.subnets[local.private_subnet_name].self_link
  pods_range_name     = local.pods_range_name
  services_range_name = local.services_range_name

  node_service_account = module.iam.gke_node_sa_email

  enable_private_endpoint    = var.enable_private_endpoint
  master_authorized_networks = var.master_authorized_networks
  master_ipv4_cidr_block     = "172.16.0.32/28"

  # production tracks the STABLE channel and protects against accidental deletion.
  release_channel     = "STABLE"
  deletion_protection = var.deletion_protection
  resource_labels     = local.labels

  # production: a stable general pool plus a spot pool for interruptible workloads.
  node_pools = {
    general = {
      machine_type   = "e2-standard-8"
      disk_size_gb   = 200
      disk_type      = "pd-ssd"
      min_node_count = 3
      max_node_count = 10
      spot           = false
      max_surge      = 2
      tags           = ["gke-node", "${local.name_prefix}-gke"]
    }
    spot = {
      machine_type   = "e2-standard-4"
      disk_size_gb   = 100
      min_node_count = 0
      max_node_count = 8
      spot           = true
      tags           = ["gke-node", "${local.name_prefix}-gke", "spot"]
      taints = [
        { key = "cloud.google.com/gke-spot", value = "true", effect = "NO_SCHEDULE" },
      ]
    }
  }
}

module "cloud_armor" {
  source = "../../modules/cloud-armor"

  project_id  = module.project.project_id
  policy_name = "${local.name_prefix}-armor"

  # production: WAF fully enforced with adaptive protection and tighter limits.
  enforce                     = var.cloud_armor_enforce
  enable_adaptive_protection  = true
  waf_sensitivity             = 2
  rate_limit_threshold_count  = 60
  rate_limit_ban_duration_sec = 600
  blocked_country_codes       = var.blocked_country_codes
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_id  = module.project.project_id
  name_prefix = local.name_prefix

  email_notification_address = var.alert_email
  log_sink_destination       = var.log_sink_destination
  alert_enabled              = true
  node_cpu_threshold         = 0.80
  pod_restart_threshold      = 3
}
