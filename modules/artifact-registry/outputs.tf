output "url" {
  description = "Image prefix, e.g. \"asia-southeast1-docker.pkg.dev/PROJECT/REPO\"."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.this.repository_id}"
}
