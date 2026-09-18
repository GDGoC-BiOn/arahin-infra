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
