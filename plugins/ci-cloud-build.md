---
name: ci-cloud-build
description: Adds Google Cloud Build configuration
---

# Cloud Build Plugin

Create the following file in the project directory.

## cloudbuild.yaml

Write `{{PROJECT_DIR}}/cloudbuild.yaml`:

```yaml
steps:
  # Install dependencies
  - name: node:22
    entrypoint: corepack
    args: ["enable"]

  - name: node:22
    entrypoint: corepack
    args: ["prepare", "pnpm@latest", "--activate"]

  - name: node:22
    entrypoint: pnpm
    args: ["install", "--frozen-lockfile"]

  # Run checks
  - name: node:22
    entrypoint: pnpm
    args: ["typecheck"]

  - name: node:22
    entrypoint: pnpm
    args: ["test"]

  - name: node:22
    entrypoint: pnpm
    args: ["build"]

  # Build and push container
  - name: gcr.io/cloud-builders/docker
    args:
      - build
      - -t
      - gcr.io/$PROJECT_ID/{{PROJECT_NAME}}:$COMMIT_SHA
      - -t
      - gcr.io/$PROJECT_ID/{{PROJECT_NAME}}:latest
      - .

  # Deploy to Cloud Run
  - name: gcr.io/google.com/cloudsdktool/cloud-sdk
    entrypoint: gcloud
    args:
      - run
      - deploy
      - {{PROJECT_NAME}}
      - --image=gcr.io/$PROJECT_ID/{{PROJECT_NAME}}:$COMMIT_SHA
      - --region={{GCP_REGION}}
      - --platform=managed
      - --allow-unauthenticated

images:
  - gcr.io/$PROJECT_ID/{{PROJECT_NAME}}:$COMMIT_SHA
  - gcr.io/$PROJECT_ID/{{PROJECT_NAME}}:latest

options:
  logging: CLOUD_LOGGING_ONLY
```
