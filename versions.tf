terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }

  # State lives in GCS, not in this git repo — it can contain secret values
  # (the generated JWT secret and DB password pass through here as outputs).
  # Versioning is on for recovery; access is controlled by IAM on the bucket,
  # same as any other prod credential.
  backend "gcs" {
    bucket = "arahin-509007-tfstate"
    prefix = "arahin-infra"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
