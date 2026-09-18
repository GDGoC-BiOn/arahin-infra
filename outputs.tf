output "backend_url" {
  value = module.backend_service.uri
}

output "parser_url" {
  value = module.parser_service.uri
}

output "ai_url" {
  value = module.ai_service.uri
}

output "artifact_registry_url" {
  value = module.artifact_registry.url
}

output "cloud_sql_connection_name" {
  value = module.db.connection_name
}

# For each app repo's workflow: google-github-actions/auth@v2's
# workload_identity_provider and service_account inputs.
output "ci_workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.github.name
}

output "ci_deployer_email" {
  value = google_service_account.ci_deployer.email
}
