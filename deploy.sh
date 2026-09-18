#!/usr/bin/env bash
# Builds only the services whose source actually changed since the last
# deploy, pushes to Artifact Registry via Cloud Build (sidesteps the
# arm64/amd64 mismatch a local `docker build` on Apple Silicon would hit for
# arahin-parser), then applies Terraform with those image tags.
#
# Each app is tagged with its own repo's git SHA — content-addressed, so if
# that exact tag is already in Artifact Registry we skip rebuilding it. A
# dirty working tree always rebuilds (tagged "<sha>-dirty-<timestamp>", since
# a dirty tree has no fixed content to address by SHA alone).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

PROJECT_ID="arahin-509007"
REGION="asia-southeast1"
REPO="arahin"
AR="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}"

# First run on a fresh project: the Artifact Registry repo has to exist
# before anything can be pushed to it. Re-running this is a no-op once it does.
terraform apply -target=google_project_service.apis -target=module.artifact_registry

declare -A TAGS
for app in arahin-parser arahin-ai arahin-backend; do
  dir="../$app"
  sha="$(git -C "$dir" rev-parse --short HEAD)"
  if [ -n "$(git -C "$dir" status --porcelain)" ]; then
    tag="${sha}-dirty-$(date +%s)"
  else
    tag="$sha"
  fi
  TAGS[$app]="$tag"

  if gcloud artifacts docker images describe "${AR}/${app}:${tag}" --project "$PROJECT_ID" >/dev/null 2>&1; then
    echo "==> $app:$tag already pushed, skipping build"
  else
    echo "==> building $app:$tag"
    gcloud builds submit "$dir" --tag "${AR}/${app}:${tag}" --project "$PROJECT_ID"
  fi
done

echo "==> terraform apply"
terraform apply \
  -var "parser_image_tag=${TAGS[arahin-parser]}" \
  -var "ai_image_tag=${TAGS[arahin-ai]}" \
  -var "backend_image_tag=${TAGS[arahin-backend]}"
