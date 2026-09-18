# Lets each app repo's GitHub Actions workflow deploy on push to main,
# authenticated via Workload Identity Federation — no long-lived JSON key
# sitting in a GitHub secret. See docs/ci-deploy.md for the workflow side.

locals {
  ci_repos = [
    "GDGoC-BiOn/arahin-backend",
    "GDGoC-BiOn/arahin-parser",
    "GDGoC-BiOn/arahin-ai",
    "GDGoC-BiOn/arahin-infra",
  ]
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-actions"
  depends_on                = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }
  # Belt-and-suspenders alongside the per-repo IAM bindings below: even a
  # token from a repo nobody granted access to is rejected at the pool level
  # if it's outside this org.
  attribute_condition = "assertion.repository_owner == 'GDGoC-BiOn'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "ci_deployer" {
  project      = var.project_id
  account_id   = "gh-actions-deployer"
  display_name = "GitHub Actions: terraform apply / image push"
}

# One binding per repo (not the whole pool) — only these four can impersonate
# the deployer, not anything else in the org.
resource "google_service_account_iam_member" "ci_deployer_wif" {
  for_each = toset(local.ci_repos)

  service_account_id = google_service_account.ci_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${each.value}"
}

# Broad by necessity: this SA runs `terraform apply` for the whole stack
# (Cloud Run, Cloud SQL, Secret Manager, the runtime service accounts, the
# VPC/peering). Scoped to resource-type admin roles rather than
# roles/editor, but still wide — this is a small project, not a
# defense-in-depth requirement.
resource "google_project_iam_member" "ci_deployer_roles" {
  for_each = toset([
    "roles/run.admin",
    # repoAdmin, not writer: writer can read/push artifacts but can't
    # create/update/delete the repository resource itself.
    "roles/artifactregistry.repoAdmin",
    "roles/cloudbuild.builds.editor",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountAdmin",
    # Manages ci.tf's own WIF pool/provider — without this, the CI SA can't
    # even read the auth mechanism it's authenticating through.
    "roles/iam.workloadIdentityPoolAdmin",
    "roles/cloudsql.admin",
    "roles/secretmanager.admin",
    "roles/compute.networkAdmin",
    "roles/servicenetworking.networksAdmin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/resourcemanager.projectIamAdmin",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.ci_deployer.email}"
}

# terraform's GCS backend needs to read/write the state object itself, and
# to manage this exact binding on later runs it needs storage.admin, not just
# storage.objectAdmin — object-level roles can't getIamPolicy on the bucket.
resource "google_storage_bucket_iam_member" "ci_deployer_state" {
  bucket = "arahin-509007-tfstate"
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.ci_deployer.email}"
}

# gcloud builds submit uploads source here. cloudbuild.builds.editor covers
# creating the build itself but not writing to this bucket — a build-owning
# human account gets that implicitly (legacy project-editor ACLs on the
# auto-created bucket), a plain service account does not.
resource "google_storage_bucket_iam_member" "ci_deployer_cloudbuild_source" {
  bucket = "arahin-509007_cloudbuild"
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.ci_deployer.email}"
}
