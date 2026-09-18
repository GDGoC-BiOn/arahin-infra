# Auto-deploy on push to main

Each of the four repos (arahin-backend, arahin-parser, arahin-ai,
arahin-infra) has a `.github/workflows/deploy.yml` that runs on push to
`main`:

1. Auth to GCP via Workload Identity Federation (`ci.tf` in this repo) — no
   JSON key in any GitHub secret.
2. An app repo builds its own image, tags it with the commit SHA, pushes to
   Artifact Registry (skipped if that tag already exists — same rule as
   `deploy.sh`).
3. Every workflow (app or infra) checks out this repo (public, so a plain
   `actions/checkout` with `repository: GDGoC-BiOn/arahin-infra` needs no
   token) and runs `terraform apply`.

## Why each workflow re-fetches the other two services' tags

Terraform variables don't persist between runs — only what's in state does,
and state holds the *resource's* resolved value, not the variable. If a
workflow ran `terraform apply -var backend_image_tag=$SHA` alone, the other
two vars would fall back to their `latest` default and Terraform would try
to redeploy parser/ai to a tag that was never pushed.

So every workflow, before applying, resolves the *currently running* image
tag for the two services it isn't deploying:

```sh
gcloud run services describe arahin-parser --region asia-southeast1 \
  --format='value(spec.template.spec.containers[0].image)' | sed 's/.*://'
```

and passes all three tags on every apply. The infra repo's own workflow
(no new image to build) does this for all three, so infra-only changes
(env vars, scaling, IAM) apply without touching what's actually running.

## Concurrency

The GCS backend's native state locking means two workflows apply-ing at once
serialize (one waits, or fails fast) rather than corrupt state. Each
workflow also sets `concurrency: terraform-apply` so a repo doesn't race
itself on rapid pushes.

## What to paste into each app repo's workflow

`google-github-actions/auth@v2` inputs, from this repo's outputs:

```sh
terraform output -raw ci_workload_identity_provider
terraform output -raw ci_deployer_email
```
