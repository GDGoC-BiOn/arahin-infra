#!/usr/bin/env bash
# Builds all three services from their sibling repos, pushes to Artifact
# Registry via Cloud Build (sidesteps the arm64/amd64 mismatch a local
# `docker build` on Apple Silicon would hit for arahin-parser), then applies
# Terraform with that image tag.
#
# Usage: ./deploy.sh [tag]   (tag defaults to a timestamp)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

PROJECT_ID="arahin-509007"
REGION="asia-southeast1"
REPO="arahin"
TAG="${1:-$(date +%Y%m%d%H%M%S)}"
AR="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}"

# First run on a fresh project: the Artifact Registry repo has to exist
# before anything can be pushed to it. Re-running this is a no-op once it does.
terraform apply -target=google_project_service.apis -target=module.artifact_registry

for app in arahin-parser arahin-ai arahin-backend; do
  echo "==> building $app"
  gcloud builds submit "../$app" --tag "${AR}/${app}:${TAG}" --project "$PROJECT_ID"
done

echo "==> terraform apply with image_tag=$TAG"
terraform apply -var "image_tag=$TAG"
