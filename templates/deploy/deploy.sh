#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# deploy.sh -- Deploy {{PROJECT_NAME}} to Cloud Run
# =============================================================================
# Prerequisites:
#   - gcloud CLI authenticated
#   - direnv active (sets GCP_PROJECT_ID, GCP_REGION)
#
# Usage:
#   ./scripts/deploy.sh
# =============================================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ---------------------------------------------------------------------------
# Project guard
# ---------------------------------------------------------------------------
EXPECTED_PROJECT="{{GCP_PROJECT_ID}}"

if [[ "${GCP_PROJECT_ID:-}" != "$EXPECTED_PROJECT" ]]; then
  die "GCP_PROJECT_ID is '${GCP_PROJECT_ID:-<unset>}', expected '$EXPECTED_PROJECT'. Make sure direnv is loaded."
fi

info "Deploying to project: $GCP_PROJECT_ID (region: ${GCP_REGION:-unset})"

# ---------------------------------------------------------------------------
# Deploy -- uncomment and customize for your service
# ---------------------------------------------------------------------------
# gcloud run deploy {{PROJECT_NAME}} \
#   --quiet \
#   --source . \
#   --region "$GCP_REGION" \
#   --project "$GCP_PROJECT_ID" \
#   --allow-unauthenticated \
#   --memory 512Mi \
#   --cpu 1 \
#   --min-instances 0 \
#   --max-instances 3

info "Deploy command not yet configured. Edit scripts/deploy.sh to add your deployment."
