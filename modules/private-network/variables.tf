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

# /28 (16 addresses) was too small — Direct VPC egress's health check
# failed with "no sufficient IP addresses" even for a single instance.
variable "run_subnet_cidr" {
  type    = string
  default = "10.8.0.0/24"
}
