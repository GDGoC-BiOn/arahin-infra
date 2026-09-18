resource "random_password" "jwt" {
  length  = 48
  special = false
}

resource "google_secret_manager_secret" "jwt_secret" {
  project   = var.project_id
  secret_id = "arahin-jwt-secret"
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "jwt_secret" {
  secret      = google_secret_manager_secret.jwt_secret.id
  secret_data = random_password.jwt.result
}

resource "google_secret_manager_secret" "database_url" {
  project   = var.project_id
  secret_id = "arahin-database-url"
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "database_url" {
  secret      = google_secret_manager_secret.database_url.id
  secret_data = module.db.database_url
}

resource "google_secret_manager_secret_iam_member" "backend_jwt" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.jwt_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.sa_backend.email}"
}

resource "google_secret_manager_secret_iam_member" "backend_database_url" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.database_url.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.sa_backend.email}"
}
