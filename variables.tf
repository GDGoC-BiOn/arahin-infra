variable "project_id" {
  type    = string
  default = "arahin-509007"
}

variable "region" {
  type    = string
  default = "asia-southeast1"
}

# Overridden per deploy: `terraform apply -var image_tag=<git-sha>`. Every
# service shares one tag so a deploy is reproducible from a single commit.
variable "image_tag" {
  type    = string
  default = "latest"
}

# Set after the first apply, once you know https://arahin-backend-xxxx.<region>.run.app
# (or a custom domain). Empty means the backend falls back to
# http://localhost:$PORT for password-reset links and the OAuth redirect —
# fine for a first deploy, wrong for anything user-facing.
variable "app_url" {
  type    = string
  default = ""
}
