resource "google_cloud_run_v2_service" "this" {
  project             = var.project_id
  name                = var.name
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    service_account = var.service_account_email
    timeout         = "${var.timeout_seconds}s"

    scaling {
      min_instance_count = var.min_instance_count
      max_instance_count = var.max_instance_count
    }

    containers {
      image = var.image

      ports {
        container_port = var.port
      }

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      dynamic "env" {
        for_each = var.env
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secret_env
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret_id
              version = env.value.version
            }
          }
        }
      }

      dynamic "volume_mounts" {
        for_each = length(var.cloudsql_instances) > 0 ? [1] : []
        content {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }
      }
    }

    dynamic "volumes" {
      for_each = length(var.cloudsql_instances) > 0 ? [1] : []
      content {
        name = "cloudsql"
        cloud_sql_instance {
          instances = var.cloudsql_instances
        }
      }
    }

    # Direct VPC egress — needed to reach a private-IP-only Cloud SQL instance
    # (this project's org policy forbids a public IP). No VPC Access
    # Connector resource required.
    dynamic "vpc_access" {
      for_each = var.vpc_subnetwork == null ? [] : [1]
      content {
        network_interfaces {
          network    = var.vpc_network
          subnetwork = var.vpc_subnetwork
        }
        egress = "PRIVATE_RANGES_ONLY"
      }
    }
  }
}

# Cloud Run's IAM check is what actually makes a service "private" — everyone
# without an explicit binding gets 403, regardless of network ingress. See
# https://cloud.google.com/run/docs/authenticating/service-to-service.
resource "google_cloud_run_v2_service_iam_member" "invoker" {
  for_each = var.allow_unauthenticated ? toset([]) : toset(var.invoker_members)

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = each.value
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  count = var.allow_unauthenticated ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
