locals {
  # Expand (repo x reader) and (repo x writer) into flat maps for IAM members.
  reader_bindings = merge([
    for repo_id, _ in var.repositories : {
      for m in var.reader_members : "${repo_id}:${m}" => { repo = repo_id, member = m }
    }
  ]...)

  writer_bindings = merge([
    for repo_id, _ in var.repositories : {
      for m in var.writer_members : "${repo_id}:${m}" => { repo = repo_id, member = m }
    }
  ]...)
}

resource "google_artifact_registry_repository" "this" {
  for_each = var.repositories

  project       = var.project_id
  location      = var.location
  repository_id = each.key
  format        = each.value.format
  description   = each.value.description
  labels        = each.value.labels

  # docker_config (immutable tags) only applies to DOCKER repositories.
  dynamic "docker_config" {
    for_each = upper(each.value.format) == "DOCKER" ? [1] : []
    content {
      immutable_tags = each.value.immutable_tags
    }
  }

  cleanup_policy_dry_run = false

  # Retain the N most recent versions regardless of tag state.
  cleanup_policies {
    id     = "keep-recent-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = each.value.keep_most_recent
    }
  }

  # Delete untagged images older than the configured age.
  cleanup_policies {
    id     = "delete-old-untagged"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = "${each.value.delete_untagged_older_than_days * 86400}s"
    }
  }
}

resource "google_artifact_registry_repository_iam_member" "reader" {
  for_each = local.reader_bindings

  project    = var.project_id
  location   = var.location
  repository = google_artifact_registry_repository.this[each.value.repo].repository_id
  role       = "roles/artifactregistry.reader"
  member     = each.value.member
}

resource "google_artifact_registry_repository_iam_member" "writer" {
  for_each = local.writer_bindings

  project    = var.project_id
  location   = var.location
  repository = google_artifact_registry_repository.this[each.value.repo].repository_id
  role       = "roles/artifactregistry.writer"
  member     = each.value.member
}
