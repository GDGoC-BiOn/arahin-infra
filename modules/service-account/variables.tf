variable "project_id" {
  type = string
}

variable "account_id" {
  type        = string
  description = "Service account ID, e.g. \"arahin-backend-run\". Max 30 chars."
}

variable "display_name" {
  type = string
}

variable "project_roles" {
  type        = list(string)
  description = "Project-level IAM roles granted to this service account."
  default     = []
}
