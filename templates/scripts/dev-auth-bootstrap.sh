#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_GCP_PROJECT_ID="{{GCP_PROJECT_ID}}"
DEFAULT_GCP_PROJECT_ID_DEV=""
DEFAULT_GCP_REGION="{{GCP_REGION}}"
DEFAULT_MODE="impersonation"

CLOUDSDK_CONFIG_DEFAULT="${REPO_ROOT}/.devcontainer/.state/gcloud"
AUTH_DIR="${REPO_ROOT}/.devcontainer/.auth"
SECRETS_DIR="${REPO_ROOT}/.devcontainer/.secrets"
STATE_FILE="${AUTH_DIR}/bootstrap-state.env"

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/dev-auth-bootstrap.sh [impersonation|wif|key] [options]

Options:
  --project <project-id>              Override target GCP project ID.
  --region <region>                   Override target region.
  --service-account <email>           Service account for impersonation mode.
  --cred-file <path>                  Credential file for wif/key mode.
  --yes                               Non-interactive where possible.
  --help                              Show this help.

Auth priority:
  1) impersonation (default)
  2) wif
  3) key (last resort)
USAGE
}

MODE="${1:-$DEFAULT_MODE}"
if [[ "$MODE" == "--help" || "$MODE" == "-h" ]]; then
  usage
  exit 0
fi
if [[ "$MODE" != "impersonation" && "$MODE" != "wif" && "$MODE" != "key" ]]; then
  echo "Unknown mode: $MODE"
  usage
  exit 1
fi
shift || true

PROJECT_ID="${GCP_PROJECT_ID:-${PROJECT_ID:-}}"
REGION="${GCP_REGION:-${REGION:-$DEFAULT_GCP_REGION}}"
SERVICE_ACCOUNT="${GCP_DEV_IMPERSONATE_SERVICE_ACCOUNT:-}"
CRED_FILE="${GCP_DEV_CREDENTIAL_FILE:-}"
ASSUME_YES=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_ID="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    --service-account)
      SERVICE_ACCOUNT="$2"
      shift 2
      ;;
    --cred-file)
      CRED_FILE="$2"
      shift 2
      ;;
    --yes)
      ASSUME_YES=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$PROJECT_ID" ]]; then
  if [[ -n "$DEFAULT_GCP_PROJECT_ID_DEV" && "${SIGNALS_ENV:-prod}" == "dev" ]]; then
    PROJECT_ID="$DEFAULT_GCP_PROJECT_ID_DEV"
  else
    PROJECT_ID="$DEFAULT_GCP_PROJECT_ID"
  fi
fi

mkdir -p "$CLOUDSDK_CONFIG_DEFAULT" "$AUTH_DIR" "$SECRETS_DIR"
export CLOUDSDK_CONFIG="${CLOUDSDK_CONFIG:-$CLOUDSDK_CONFIG_DEFAULT}"
mkdir -p "$CLOUDSDK_CONFIG"

if ! command -v gcloud >/dev/null 2>&1; then
  echo "gcloud CLI is required. In dev container it should be preinstalled."
  exit 1
fi

if [[ -z "$PROJECT_ID" ]]; then
  if [[ "$ASSUME_YES" == true ]]; then
    echo "Missing project id. Set GCP_PROJECT_ID or pass --project."
    exit 1
  fi
  read -r -p "Target GCP project ID: " PROJECT_ID
fi

if [[ -z "$PROJECT_ID" ]]; then
  echo "Project id is required."
  exit 1
fi

gcloud config set project "$PROJECT_ID" >/dev/null

write_state() {
  cat > "$STATE_FILE" <<STATE
GCP_DEV_AUTH_MODE=$MODE
GCP_PROJECT_ID=$PROJECT_ID
GCP_REGION=$REGION
GCP_DEV_IMPERSONATE_SERVICE_ACCOUNT=${SERVICE_ACCOUNT:-}
GCP_DEV_CREDENTIAL_SOURCE=${CRED_FILE:-}
CLOUDSDK_CONFIG=$CLOUDSDK_CONFIG
STATE
}

copy_credential_to_adc() {
  local source_file="$1"
  local target_adc="$CLOUDSDK_CONFIG/application_default_credentials.json"
  local target_copy="$AUTH_DIR/active-credential.json"
  cp "$source_file" "$target_adc"
  cp "$source_file" "$target_copy"
  chmod 600 "$target_adc" "$target_copy" 2>/dev/null || true
}

prompt_for_cred_file() {
  local label="$1"
  if [[ -z "$CRED_FILE" ]]; then
    read -r -p "$label credential file path: " CRED_FILE
  fi
  if [[ -z "$CRED_FILE" ]]; then
    echo "Credential file is required for mode '$MODE'."
    exit 1
  fi
  if [[ ! -f "$CRED_FILE" ]]; then
    echo "Credential file not found: $CRED_FILE"
    exit 1
  fi
}

run_with_impersonation_hints() {
  local output
  if output=$("$@" 2>&1); then
    return 0
  fi

  echo "$output" >&2

  if [[ "$output" == *"Gaia id not found for email"* ]]; then
    echo "Hint: impersonation target is invalid or in the wrong project." >&2
    echo "Hint: use a real service account email ending in .iam.gserviceaccount.com." >&2
  fi

  if [[ "$output" == *"Failed to impersonate"* ]]; then
    echo "Hint: ensure your user has roles/iam.serviceAccountTokenCreator on the target service account." >&2
  fi

  if [[ "$output" == *"NOT_FOUND"* && "$output" == *"Failed to impersonate"* ]]; then
    echo "Hint: project and service account likely do not match. Verify --project and --service-account." >&2
  fi

  echo "Hint: run ./scripts/dev-auth-ensure-sa.sh --project \"$PROJECT_ID\" --me <you@example.com> --region \"$REGION\" --sa-id <sa-id>" >&2
  return 1
}

case "$MODE" in
  impersonation)
    if [[ -z "$SERVICE_ACCOUNT" ]]; then
      if [[ "$ASSUME_YES" == true ]]; then
        echo "Missing GCP_DEV_IMPERSONATE_SERVICE_ACCOUNT for impersonation mode."
        exit 1
      fi
      read -r -p "Service account email for impersonation: " SERVICE_ACCOUNT
    fi

    if [[ -z "$SERVICE_ACCOUNT" ]]; then
      echo "Service account email is required for impersonation mode."
      exit 1
    fi

    if [[ ! "$SERVICE_ACCOUNT" =~ ^[a-z][a-z0-9-]{4,28}[a-z0-9]@[a-z][a-z0-9-]{4,28}[a-z0-9]\.iam\.gserviceaccount\.com$ ]]; then
      echo "Invalid service account email for impersonation mode: $SERVICE_ACCOUNT" >&2
      echo "Expected format: <sa-id>@<project-id>.iam.gserviceaccount.com" >&2
      echo "Do not use a human user email here." >&2
      echo "Hint: run ./scripts/dev-auth-ensure-sa.sh --project \"$PROJECT_ID\" --me <you@example.com> --region \"$REGION\" --sa-id <sa-id>" >&2
      exit 1
    fi

    ACTIVE_ACCOUNT="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' | head -n1 || true)"
    if [[ -z "$ACTIVE_ACCOUNT" ]]; then
      echo "No active gcloud user account found. Starting interactive login..."
      gcloud auth login --update-adc
    fi

    gcloud config unset auth/impersonate_service_account >/dev/null 2>&1 || true
    gcloud config set auth/impersonate_service_account "$SERVICE_ACCOUNT" >/dev/null

    echo "Running ADC login for impersonated service account..."
    run_with_impersonation_hints gcloud auth application-default login --impersonate-service-account="$SERVICE_ACCOUNT" --project="$PROJECT_ID"

    echo "Validating impersonated CLI token..."
    run_with_impersonation_hints gcloud auth print-access-token >/dev/null
    ;;

  wif)
    prompt_for_cred_file "WIF"
    gcloud config unset auth/impersonate_service_account >/dev/null 2>&1 || true

    echo "Configuring CLI auth from WIF credential file..."
    gcloud auth login --cred-file="$CRED_FILE"
    copy_credential_to_adc "$CRED_FILE"
    ;;

  key)
    echo "WARNING: key mode is last resort. Prefer impersonation or WIF when possible."
    prompt_for_cred_file "Service account key"
    gcloud config unset auth/impersonate_service_account >/dev/null 2>&1 || true

    echo "Configuring CLI auth from service account key..."
    gcloud auth activate-service-account --key-file="$CRED_FILE"
    copy_credential_to_adc "$CRED_FILE"
    ;;
esac

write_state

echo
echo "Bootstrap complete"
echo "  mode:              $MODE"
echo "  project:           $PROJECT_ID"
echo "  region:            $REGION"
echo "  cloudsdk config:   $CLOUDSDK_CONFIG"
echo "  state file:        $STATE_FILE"
echo
echo "Next: ./scripts/dev-auth-doctor.sh"
