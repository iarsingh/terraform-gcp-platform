output "repositories" {
  description = "Map of repository ID to name and full path (LOCATION-docker.pkg.dev/PROJECT/REPO)."
  value = {
    for id, r in google_artifact_registry_repository.this : id => {
      name = r.name
      id   = r.id
      path = "${var.location}-docker.pkg.dev/${var.project_id}/${r.repository_id}"
    }
  }
}
