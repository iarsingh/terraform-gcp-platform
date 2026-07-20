locals {
  # Exactly one of org_id / folder_id must be provided as the parent.
  parent_valid = (var.org_id == null) != (var.folder_id == null)
}

# Fail fast during plan if the parent configuration is ambiguous.
resource "null_resource" "parent_guard" {
  count = local.parent_valid ? 0 : 1

  # This will surface a clear error: exactly one parent must be set.
  lifecycle {
    precondition {
      condition     = local.parent_valid
      error_message = "Exactly one of org_id or folder_id must be set as the project parent."
    }
  }
}

resource "google_project" "this" {
  name       = var.project_name
  project_id = var.project_id

  org_id    = var.org_id
  folder_id = var.folder_id

  billing_account     = var.billing_account
  auto_create_network = var.auto_create_network

  labels = var.labels

  # Prevent accidental deletion of the project through Terraform.
  deletion_policy = "PREVENT"
}

# Enable each required API. for_each keeps the set stable regardless of ordering.
resource "google_project_service" "apis" {
  for_each = toset(var.activate_apis)

  project = google_project.this.project_id
  service = each.value

  disable_dependent_services = false
  disable_on_destroy         = var.disable_services_on_destroy
}
