# arahin-infra

Terraform for arahin-backend, arahin-parser, and arahin-ai on Cloud Run
(region: `asia-southeast1`, project: `arahin-509007`).

## Layout

- `modules/cloud-run-service` — one Cloud Run v2 service. Used three times
  (parser, ai, backend); the only difference between instances is env vars,
  the image, and whether it is public.
- `modules/service-account` — a runtime service account plus its project IAM
  roles.
- `modules/cloud-sql` — the Postgres instance for arahin-backend.
- `modules/artifact-registry` — the Docker repo all three images live in.
- `main.tf` / `secrets.tf` / `apis.tf` — wires the modules together, and the
  two Secret Manager secrets (`arahin-jwt-secret`, `arahin-database-url`).

## Backend-to-backend auth

arahin-parser and arahin-ai are **not** publicly reachable
(`allow_unauthenticated = false`, the default) — only `arahin-backend-run`'s
service account has `roles/run.invoker` on them. arahin-backend attaches a
Google-signed ID token to every outbound call (see
`arahin-backend/internal/platform/svcauth`), which is what Cloud Run checks
against that IAM binding. arahin-backend itself is public
(`allow_unauthenticated = true`) since it's the API entrypoint.

## State

Remote, in `gs://arahin-509007-tfstate` (versioned, not in this repo — it can
hold the generated JWT secret and DB password as plain resource attributes).
This repo tracks the *code*; `terraform plan` against that bucket is what
tells you what's actually deployed.

## First-time setup

```sh
terraform init
./deploy.sh          # builds all 3 images via Cloud Build, pushes, applies
```

After the first apply, get the backend URL and set it as `APP_URL` (used for
password-reset links and the Google OAuth redirect default):

```sh
terraform apply -var "app_url=$(terraform output -raw backend_url)"
```

## Subsequent deploys

```sh
./deploy.sh                # tags images with a timestamp
./deploy.sh $(git -C ../arahin-backend rev-parse --short HEAD)   # or a real sha
```

## Existing arahin-ai service

There is a pre-Terraform `arahin-ai` Cloud Run service in `us-central1`
(deployed manually via `gcloud run deploy --source`). This config creates a
*separate* `arahin-ai` service in `asia-southeast1`; once the new one is
verified working, delete the old one manually:

```sh
gcloud run services delete arahin-ai --region us-central1 --project arahin-509007
```

## Local dev

Nothing here affects `arahin-backend`'s local `PARSER_BASE_URL=http://localhost:8081`
/ `AI_BASE_URL=` (stub mode) — the ID-token auth in `svcauth` only kicks in
for `https://` URLs.
