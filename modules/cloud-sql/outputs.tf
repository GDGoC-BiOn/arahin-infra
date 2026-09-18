output "connection_name" {
  value = google_sql_database_instance.this.connection_name
}

# Unix-socket DSN for a Cloud Run container with this instance attached as a
# volume at /cloudsql (see modules/cloud-run-service). No VPC connector needed.
output "database_url" {
  value     = "postgres://${google_sql_user.this.name}:${random_password.db.result}@localhost/${google_sql_database.this.name}?host=/cloudsql/${google_sql_database_instance.this.connection_name}&sslmode=disable"
  sensitive = true
}
