#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_EXPECTED_PROJECT="{{GCP_PROJECT_ID}}"
CLOUDSDK_CONFIG_DEFAULT="${REPO_ROOT}/.devcontainer/.state/gcloud"
export CLOUDSDK_CONFIG="${CLOUDSDK_CONFIG:-$CLOUDSDK_CONFIG_DEFAULT}"

EXPECTED_PROJECT="${GCP_PROJECT_ID:-${PROJECT_ID:-$DEFAULT_EXPECTED_PROJECT}}"
ADC_FILE="$CLOUDSDK_CONFIG/application_default_credentials.json"
STATE_FILE="${REPO_ROOT}/.devcontainer/.auth/bootstrap-state.env"

FAILURES=0

ok() {
  printf '[ok] %s\n' "$1"
}

fail() {
  printf '[fail] %s\n' "$1"
  FAILURES=$((FAILURES + 1))
}

check_cmd() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "Running local GCP auth diagnostics"
echo "  CLOUDSDK_CONFIG=$CLOUDSDK_CONFIG"

action_project="$(gcloud config get-value project 2>/dev/null || true)"
impersonated_sa="$(gcloud config get-value auth/impersonate_service_account 2>/dev/null || true)"
active_account="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null | head -n1 || true)"

check_cmd "gcloud is available" command -v gcloud
check_cmd "CLOUDSDK_CONFIG directory exists" test -d "$CLOUDSDK_CONFIG"

if [[ -n "$EXPECTED_PROJECT" ]]; then
  if [[ "$action_project" == "$EXPECTED_PROJECT" ]]; then
    ok "active project matches expected ($EXPECTED_PROJECT)"
  else
    fail "active project mismatch (expected='$EXPECTED_PROJECT' actual='${action_project:-<unset>}')"
  fi
else
  echo "[warn] expected project not configured; skipping project match check"
fi

if [[ -n "$active_account" ]]; then
  ok "active CLI account detected ($active_account)"
else
  fail "no active CLI account"
fi

if [[ -n "$impersonated_sa" ]]; then
  ok "impersonation configured ($impersonated_sa)"
else
  echo "[warn] no impersonated service account configured"
fi

check_cmd "CLI token (gcloud auth print-access-token)" gcloud auth print-access-token

if [[ -f "$ADC_FILE" ]]; then
  ok "ADC file present at $ADC_FILE"
else
  echo "[warn] ADC file not found at $ADC_FILE"
fi

check_cmd "ADC token (gcloud auth application-default print-access-token)" gcloud auth application-default print-access-token

if [[ -f "$STATE_FILE" ]]; then
  ok "bootstrap state file present"
else
  echo "[warn] bootstrap state file missing (run dev-auth-bootstrap.sh to create)"
fi

echo
if [[ $FAILURES -eq 0 ]]; then
  echo "Diagnostics passed"
  exit 0
fi

echo "Diagnostics failed with $FAILURES failing checks"
exit 1
