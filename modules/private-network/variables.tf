variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  type    = string
  default = "arahin"
}

variable "run_subnet_cidr" {
  type    = string
  default = "10.8.0.0/28"
}
