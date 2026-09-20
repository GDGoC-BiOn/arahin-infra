# sqladmin.googleapis.com is the one required API this project didn't
# already have enabled; the rest are here so a from-scratch project works too.
resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com",
    "aiplatform.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    # Required for every google_project_iam_member/google_project_service
    # call — the human ADC path tolerated it being off, the CI service
    # account's calls got a hard 403 until this was enabled.
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "cloudtasks.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
