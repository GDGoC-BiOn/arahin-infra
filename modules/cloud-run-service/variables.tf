variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  type = string
}

variable "image" {
  type        = string
  description = "Full Artifact Registry image ref, e.g. \"REGION-docker.pkg.dev/PROJECT/REPO/NAME:TAG\"."
}

variable "service_account_email" {
  type = string
}

variable "port" {
  type    = number
  default = 8080
}

variable "cpu" {
  type    = string
  default = "1"
}

variable "memory" {
  type    = string
  default = "512Mi"
}

variable "min_instance_count" {
  type    = number
  default = 0
}

variable "max_instance_count" {
  type    = number
  default = 2
}

variable "timeout_seconds" {
  type    = number
  default = 300
}

variable "env" {
  type        = map(string)
  description = "Plain (non-secret) environment variables."
  default     = {}
}

variable "secret_env" {
  type = map(object({
    secret_id = string
    version   = optional(string, "latest")
  }))
  description = "Environment variables sourced from Secret Manager."
  default     = {}
}

# Instance connection names ("project:region:instance") to attach at
# /cloudsql via the Cloud Run-managed Cloud SQL Auth Proxy. Empty = no
# Cloud SQL volume.
variable "cloudsql_instances" {
  type    = list(string)
  default = []
}

# Public means "no IAM check" (allUsers gets roles/run.invoker). Anything not
# public is reachable only by the identities listed in invoker_members, e.g.
# "serviceAccount:arahin-backend-run@PROJECT.iam.gserviceaccount.com".
variable "allow_unauthenticated" {
  type    = bool
  default = false
}

variable "invoker_members" {
  type    = list(string)
  default = []
}
