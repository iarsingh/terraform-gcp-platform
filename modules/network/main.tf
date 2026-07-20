locals {
  subnets_by_name = { for s in var.subnets : s.name => s }
  private_subnets = [for s in var.subnets : s if s.private]
}

resource "google_compute_network" "this" {
  name                            = var.network_name
  project                         = var.project_id
  auto_create_subnetworks         = false
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = false
}

# Promote the host project to a Shared VPC host so service projects can attach.
resource "google_compute_shared_vpc_host_project" "this" {
  count   = var.enable_shared_vpc_host ? 1 : 0
  project = var.project_id
}

resource "google_compute_subnetwork" "this" {
  for_each = local.subnets_by_name

  name          = each.value.name
  project       = var.project_id
  region        = each.value.region
  network       = google_compute_network.this.id
  ip_cidr_range = each.value.ip_cidr_range

  # Private Google Access lets private nodes reach Google APIs without public IPs.
  private_ip_google_access = each.value.private

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  # VPC flow logs on private subnets for network forensics and egress auditing.
  dynamic "log_config" {
    for_each = each.value.private ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}

# ---------------------------------------------------------------------------
# Cloud Router + Cloud NAT: outbound internet for private (no public IP) nodes
# ---------------------------------------------------------------------------
resource "google_compute_router" "this" {
  name    = "${var.network_name}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.this.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "this" {
  name    = "${var.network_name}-nat"
  project = var.project_id
  region  = var.region
  router  = google_compute_router.this.name

  nat_ip_allocate_option = "AUTO_ONLY"

  # Only NAT the private subnets (and their pod/service secondary ranges).
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = { for s in local.private_subnets : s.name => s }
    content {
      name = google_compute_subnetwork.this[subnetwork.value.name].id
      source_ip_ranges_to_nat = concat(
        ["PRIMARY_IP_RANGE"],
        length(subnetwork.value.secondary_ranges) > 0 ? ["LIST_OF_SECONDARY_IP_RANGES"] : []
      )
      secondary_ip_range_names = [for r in subnetwork.value.secondary_ranges : r.range_name]
    }
  }

  # Raise per-VM ports to reduce NAT port-exhaustion risk under high fan-out.
  min_ports_per_vm                    = var.nat_min_ports_per_vm
  enable_endpoint_independent_mapping = false

  log_config {
    enable = true
    filter = var.nat_log_config
  }
}

# ---------------------------------------------------------------------------
# Firewall: deny-by-default posture + explicit, narrowly-scoped allow rules
# ---------------------------------------------------------------------------

# Explicit deny-all ingress at low priority. GCP already implies this, but an
# explicit rule makes the posture auditable and lets us attach logging.
resource "google_compute_firewall" "deny_all_ingress" {
  name      = "${var.network_name}-deny-all-ingress"
  project   = var.project_id
  network   = google_compute_network.this.id
  direction = "INGRESS"
  priority  = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow east-west traffic between internal ranges (nodes, pods, services).
resource "google_compute_firewall" "allow_internal" {
  name      = "${var.network_name}-allow-internal"
  project   = var.project_id
  network   = google_compute_network.this.id
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = var.internal_ranges
}

# Allow IAP-tunneled SSH so operators reach private nodes without public IPs.
resource "google_compute_firewall" "allow_iap_ssh" {
  name      = "${var.network_name}-allow-iap-ssh"
  project   = var.project_id
  network   = google_compute_network.this.id
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP's TCP forwarding range.
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-ssh"]
}

# Allow Google Cloud health checkers to reach backends.
resource "google_compute_firewall" "allow_health_checks" {
  name      = "${var.network_name}-allow-health-checks"
  project   = var.project_id
  network   = google_compute_network.this.id
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["lb-backend"]
}
