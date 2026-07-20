locals {
  wi_pool = coalesce(var.workload_identity_pool, "${var.project_id}.svc.id.goog")

  # Flatten workload-identity project role bindings into a single map so each
  # (service account, role) pair becomes one IAM member resource.
  wi_role_bindings = merge([
    for key, wi in var.workload_identity_bindings : {
      for role in wi.project_roles : "${key}:${role}" => {
        sa_key = key
        role   = role
      }
    }
  ]...)

  wi_secret_bindings = {
    for key, wi in var.workload_identity_bindings : key => wi
    if wi.secret_accessor
  }
}

# ---------------------------------------------------------------------------
# GKE node service account (least privilege; NOT the default compute SA)
# ---------------------------------------------------------------------------
resource "google_service_account" "gke_node" {
  project      = var.project_id
  account_id   = "${var.name_prefix}-gke-node"
  display_name = "GKE node service account (${var.name_prefix})"
  description  = "Least-privilege identity for GKE worker nodes. Not used by workloads."
}

resource "google_project_iam_member" "gke_node" {
  for_each = toset(var.node_sa_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

# ---------------------------------------------------------------------------
# Example least-privilege custom role for platform deployment automation
# ---------------------------------------------------------------------------
resource "google_project_iam_custom_role" "platform_deployer" {
  project     = var.project_id
  role_id     = var.custom_role_id
  title       = "Platform Deployer (${var.name_prefix})"
  description = "Curated deploy permissions for CI. Excludes destructive project/IAM admin."
  stage       = "GA"

  permissions = [
    "container.clusters.get",
    "container.clusters.list",
    "artifactregistry.repositories.downloadArtifacts",
    "artifactregistry.repositories.uploadArtifacts",
    "secretmanager.versions.access",
    "monitoring.timeSeries.list",
  ]
}

# ---------------------------------------------------------------------------
# Workload Identity: dedicated GSAs impersonated by Kubernetes SAs
# ---------------------------------------------------------------------------
resource "google_service_account" "workload" {
  for_each = var.workload_identity_bindings

  project      = var.project_id
  account_id   = "${var.name_prefix}-${each.key}"
  display_name = each.value.display_name
  description  = "Workload Identity GSA for ${each.value.namespace}/${each.value.ksa_name}."
}

# Allow the specific KSA to impersonate the GSA via Workload Identity.
resource "google_service_account_iam_member" "workload_identity_user" {
  for_each = var.workload_identity_bindings

  service_account_id = google_service_account.workload[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${local.wi_pool}[${each.value.namespace}/${each.value.ksa_name}]"
}

# Project roles granted to each workload GSA.
resource "google_project_iam_member" "workload_roles" {
  for_each = local.wi_role_bindings

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.workload[each.value.sa_key].email}"
}

# Optional Secret Manager access, scoped by an IAM condition to secrets that
# are prefixed with the workload's logical name (least privilege by resource).
resource "google_project_iam_member" "workload_secret_accessor" {
  for_each = local.wi_secret_bindings

  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.workload[each.key].email}"

  condition {
    title       = "only-${each.key}-secrets"
    description = "Restrict access to secrets prefixed with the workload name."
    expression  = "resource.name.startsWith(\"projects/${var.project_id}/secrets/${each.key}-\")"
  }
}
