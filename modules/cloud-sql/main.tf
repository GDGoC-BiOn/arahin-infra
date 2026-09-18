resource "random_password" "db" {
  length  = 24
  special = false
}

resource "google_sql_database_instance" "this" {
  project             = var.project_id
  name                = var.instance_name
  region              = var.region
  database_version    = "POSTGRES_17"
  deletion_protection = var.deletion_protection

  settings {
    tier = var.tier
    # This project's org policy defaults new instances to ENTERPRISE_PLUS,
    # which only accepts db-perf-optimized-* tiers. ENTERPRISE is the edition
    # that still supports the cheap shared-core db-f1-micro tier.
    edition           = "ENTERPRISE"
    availability_type = "ZONAL"
    disk_size         = 10
    disk_autoresize   = false
    backup_configuration {
      enabled = var.backups_enabled
    }
    # constraints/sql.restrictPublicIp forbids ipv4_enabled = true here.
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.private_network_id
    }
  }
}

resource "google_sql_database" "this" {
  project  = var.project_id
  instance = google_sql_database_instance.this.name
  name     = var.database_name
}

resource "google_sql_user" "this" {
  project  = var.project_id
  instance = google_sql_database_instance.this.name
  name     = var.db_user
  password = random_password.db.result
}
