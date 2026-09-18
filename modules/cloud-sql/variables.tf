variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "database_name" {
  type    = string
  default = "arahin"
}

variable "db_user" {
  type    = string
  default = "arahin"
}

variable "tier" {
  type    = string
  default = "db-f1-micro"
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "backups_enabled" {
  type    = bool
  default = false
}
