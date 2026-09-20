resource "time_sleep" "cloud_tasks_queue_admin_propagation" {
  depends_on      = [google_project_iam_member.ci_deployer_roles]
  create_duration = "30s"
}

resource "google_cloud_tasks_queue" "blueprint" {
  project  = var.project_id
  location = var.region
  name     = "blueprint-generations"

  rate_limits {
    max_dispatches_per_second = 2
    max_concurrent_dispatches = 2
  }

  retry_config {
    max_attempts  = 5
    min_backoff   = "5s"
    max_backoff   = "300s"
    max_doublings = 5
  }

  depends_on = [google_project_service.apis, time_sleep.cloud_tasks_queue_admin_propagation]
}

resource "google_cloud_tasks_queue" "lessons" {
  project  = var.project_id
  location = var.region
  name     = "blueprint-lessons"

  rate_limits {
    max_dispatches_per_second = 4
    max_concurrent_dispatches = 4
  }

  retry_config {
    max_attempts  = 5
    min_backoff   = "5s"
    max_backoff   = "300s"
    max_doublings = 5
  }

  depends_on = [google_project_service.apis, time_sleep.cloud_tasks_queue_admin_propagation]
}
