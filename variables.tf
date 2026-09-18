variable "project_id" {
  type    = string
  default = "arahin-509007"
}

variable "region" {
  type    = string
  default = "asia-southeast1"
}

# Each service is tagged with its own repo's git SHA (see deploy.sh), so
# redeploying after a change to only one service doesn't touch the others'
# running revision.
variable "parser_image_tag" {
  type    = string
  default = "latest"
}

variable "ai_image_tag" {
  type    = string
  default = "latest"
}

variable "backend_image_tag" {
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
