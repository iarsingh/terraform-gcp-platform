locals {
  env         = "dev"
  name_prefix = "acme-${local.env}"

  labels = {
    env         = local.env
    managed_by  = "terraform"
    team        = "platform"
    cost_center = "engineering"
  }

  # Subnet + secondary range names, referenced by both network and GKE modules.
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

  # dev keeps NAT ports modest to save cost; egress fan-out is low.
  nat_min_ports_per_vm = 64

  subnets = [
    {
      name          = local.public_subnet_name
      ip_cidr_range = "10.10.16.0/24"
      region        = var.region
      private       = false
    },
    {
      name          = local.private_subnet_name
      ip_cidr_range = "10.10.0.0/20"
      region        = var.region
      private       = true
      secondary_ranges = [
        { range_name = local.pods_range_name, ip_cidr_range = "10.20.0.0/16" },
        { range_name = local.services_range_name, ip_cidr_range = "10.30.0.0/20" },
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
      display_name    = "Sample API workload (dev)"
      namespace       = "apps"
      ksa_name        = "api"
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
      description                     = "Application container images (dev)"
      keep_most_recent                = 10
      delete_untagged_older_than_days = 14
    }
  }

  reader_members = ["serviceAccount:${module.iam.gke_node_sa_email}"]
}

module "gke" {
  source = "../../modules/gke"

  project_id = module.project.project_id
  name       = "${local.name_prefix}-gke"
  region     = var.region

  network             = module.network.network_self_link
  subnetwork          = module.network.subnets[local.private_subnet_name].self_link
  pods_range_name     = local.pods_range_name
  services_range_name = local.services_range_name

  node_service_account = module.iam.gke_node_sa_email

  enable_private_endpoint    = var.enable_private_endpoint
  master_authorized_networks = var.master_authorized_networks
  master_ipv4_cidr_block     = "172.16.0.0/28"

  release_channel     = "RAPID"
  deletion_protection = var.deletion_protection
  resource_labels     = local.labels

  # dev: a single small, spot-backed autoscaling pool to minimize cost.
  node_pools = {
    default = {
      machine_type   = "e2-standard-2"
      disk_size_gb   = 50
      min_node_count = 1
      max_node_count = 3
      spot           = true
      tags           = ["gke-node", "${local.name_prefix}-gke"]
    }
  }
}

module "cloud_armor" {
  source = "../../modules/cloud-armor"

  project_id  = module.project.project_id
  policy_name = "${local.name_prefix}-armor"

  # dev: preview mode so WAF rules log but do not block while tuning.
  enforce                    = var.cloud_armor_enforce
  enable_adaptive_protection = false
  waf_sensitivity            = 1
  rate_limit_threshold_count = 200
  blocked_country_codes      = var.blocked_country_codes
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_id  = module.project.project_id
  name_prefix = local.name_prefix

  email_notification_address = var.alert_email
  log_sink_destination       = var.log_sink_destination
  alert_enabled              = true
}
