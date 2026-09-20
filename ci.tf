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
    "roles/cloudtasks.queueAdmin",
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
    # Project-scoped, not bucket-scoped, on purpose: `gcloud builds submit`'s
    # preflight check calls storage.buckets.list — a *project*-level
    # operation — to find the default Cloud Build source bucket, before it
    # ever touches a specific bucket by name. A bucket-scoped grant on that
    # bucket alone (what this used to be) 403s at that list call, never gets
    # far enough to matter. This same role also covers the tfstate bucket
    # (terraform's GCS backend needs storage.admin, not just
    # storage.objectAdmin, to manage its own IAM binding on later runs —
    # object-level roles can't getIamPolicy on a bucket).
    "roles/storage.admin",
    # gcloud builds submit also streams build logs from a legacy,
    # ACL-gated bucket ("gs://PROJECT_NUMBER.cloudbuild-logs...") that only
    # project Viewer/Owner can read — confirmed by reproducing the exact
    # failure with --log-http and --impersonate-service-account before
    # adding this; storage.admin and logging.viewer alone were not enough.
    "roles/viewer",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.ci_deployer.email}"
}
