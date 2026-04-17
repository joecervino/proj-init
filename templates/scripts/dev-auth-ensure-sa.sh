#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_GCP_PROJECT_ID="{{GCP_PROJECT_ID}}"
DEFAULT_GCP_REGION="{{GCP_REGION}}"
DEFAULT_SA_ID="${GCP_DEV_SA_ID:-local-dev-codex}"
DEFAULT_ME="${GCP_DEV_ME_USER_EMAIL:-}"

CLOUDSDK_CONFIG_DEFAULT="${REPO_ROOT}/.devcontainer/.state/gcloud"
AUTH_DIR="${REPO_ROOT}/.devcontainer/.auth"
SECRETS_DIR="${REPO_ROOT}/.devcontainer/.secrets"

PROJECT_ID="${GCP_PROJECT_ID:-${PROJECT_ID:-$DEFAULT_GCP_PROJECT_ID}}"
REGION="${GCP_REGION:-${REGION:-$DEFAULT_GCP_REGION}}"
ME_USER="${DEFAULT_ME}"
SA_ID="${DEFAULT_SA_ID}"
DRY_RUN=false
SA_ROLES=()

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/dev-auth-ensure-sa.sh [options]

Options:
  --project <project-id>       Target GCP project ID.
  --me <user-email>            Human user email that will impersonate the SA.
  --sa-id <sa-id>              Service account id (default: local-dev-codex).
  --region <region>            Region used in printed bootstrap command.
  --sa-role <role>             Optional project role to grant to the SA (repeatable).
  --dry-run                    Print commands without executing them.
  --help                       Show this help.

Examples:
  ./scripts/dev-auth-ensure-sa.sh --project my-project --me you@example.com
  ./scripts/dev-auth-ensure-sa.sh --project my-project --me you@example.com --sa-role roles/viewer
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_ID="$2"
      shift 2
      ;;
    --me)
      ME_USER="$2"
      shift 2
      ;;
    --sa-id)
      SA_ID="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    --sa-role)
      SA_ROLES+=("$2")
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$PROJECT_ID" ]]; then
  read -r -p "Target GCP project ID: " PROJECT_ID || true
fi

if [[ -z "$ME_USER" ]]; then
  read -r -p "Your user email for impersonation binding: " ME_USER || true
fi

if [[ -z "$PROJECT_ID" ]]; then
  echo "Project id is required. Pass --project or set GCP_PROJECT_ID." >&2
  exit 1
fi

if [[ -z "$ME_USER" ]]; then
  echo "User email is required. Pass --me or set GCP_DEV_ME_USER_EMAIL." >&2
  exit 1
fi

if [[ ! "$SA_ID" =~ ^[a-z][a-z0-9-]{4,28}[a-z0-9]$ ]]; then
  echo "Invalid --sa-id '$SA_ID'. Expected 6-30 chars, lowercase letters/digits/hyphens." >&2
  exit 1
fi

if [[ "$ME_USER" != *@* ]]; then
  echo "Invalid --me '$ME_USER'. Expected an email address." >&2
  exit 1
fi

SA_EMAIL="${SA_ID}@${PROJECT_ID}.iam.gserviceaccount.com"

mkdir -p "$CLOUDSDK_CONFIG_DEFAULT" "$AUTH_DIR" "$SECRETS_DIR"
export CLOUDSDK_CONFIG="${CLOUDSDK_CONFIG:-$CLOUDSDK_CONFIG_DEFAULT}"
mkdir -p "$CLOUDSDK_CONFIG"
unset CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT || true

if ! command -v gcloud >/dev/null 2>&1; then
  echo "gcloud CLI is required. In dev container it should be preinstalled." >&2
  exit 1
fi

print_cmd() {
  printf '  '
  printf '%q ' "$@"
  printf '\n'
}

print_admin_handoff() {
  echo
  echo "Admin handoff commands (run with project IAM admin privileges):"
  print_cmd gcloud iam service-accounts create "$SA_ID" --project "$PROJECT_ID" --display-name "Local Dev (Codex/Claude)"
  print_cmd gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" --project "$PROJECT_ID" --member "user:${ME_USER}" --role roles/iam.serviceAccountTokenCreator
  local role
  for role in "${SA_ROLES[@]}"; do
    print_cmd gcloud projects add-iam-policy-binding "$PROJECT_ID" --member "serviceAccount:${SA_EMAIL}" --role "$role"
  done
}

run_or_handoff() {
  local step="$1"
  shift

  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] $step"
    print_cmd "$@"
    return 0
  fi

  local output
  if output=$("$@" 2>&1); then
    echo "[ok] $step"
    return 0
  fi

  echo "[fail] $step" >&2
  echo "$output" >&2
  print_admin_handoff >&2
  exit 1
}

if [[ "$DRY_RUN" == true ]]; then
  echo "[dry-run] clearing stale impersonation config (if present)"
  print_cmd gcloud config unset auth/impersonate_service_account
else
  gcloud config unset auth/impersonate_service_account >/dev/null 2>&1 || true
fi

run_or_handoff "set active project" gcloud config set project "$PROJECT_ID"

if [[ "$DRY_RUN" == true ]]; then
  echo "[dry-run] check service account and create if missing"
  print_cmd gcloud iam service-accounts describe "$SA_EMAIL" --project "$PROJECT_ID"
  print_cmd gcloud iam service-accounts create "$SA_ID" --project "$PROJECT_ID" --display-name "Local Dev (Codex/Claude)"
else
  if gcloud iam service-accounts describe "$SA_EMAIL" --project "$PROJECT_ID" >/dev/null 2>&1; then
    echo "[ok] service account already exists: $SA_EMAIL"
  else
    run_or_handoff "create service account $SA_EMAIL" gcloud iam service-accounts create "$SA_ID" --project "$PROJECT_ID" --display-name "Local Dev (Codex/Claude)"
  fi
fi

run_or_handoff "grant TokenCreator on $SA_EMAIL to user:$ME_USER" \
  gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --project "$PROJECT_ID" \
  --member "user:${ME_USER}" \
  --role roles/iam.serviceAccountTokenCreator

for role in "${SA_ROLES[@]}"; do
  run_or_handoff "grant $role to serviceAccount:$SA_EMAIL on project $PROJECT_ID" \
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member "serviceAccount:${SA_EMAIL}" \
    --role "$role"
done

echo
echo "IAM prep complete."
echo "  project:         $PROJECT_ID"
echo "  service account: $SA_EMAIL"
echo "  user:            $ME_USER"
echo
echo "Next bootstrap command:"
echo "  ./scripts/dev-auth-bootstrap.sh impersonation \\"
echo "    --project \"$PROJECT_ID\" \\"
echo "    --region \"$REGION\" \\"
echo "    --service-account \"$SA_EMAIL\""
