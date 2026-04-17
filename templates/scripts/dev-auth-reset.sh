#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${REPO_ROOT}/.devcontainer/.state/gcloud"
AUTH_DIR="${REPO_ROOT}/.devcontainer/.auth"
SECRETS_DIR="${REPO_ROOT}/.devcontainer/.secrets"

CONFIRM="${1:-}"
if [[ "$CONFIRM" != "--yes" ]]; then
  echo "This will remove repo-local GCP auth state under:"
  echo "  $STATE_DIR"
  echo "  $AUTH_DIR"
  read -r -p "Proceed? [y/N]: " answer
  case "$answer" in
    y|Y|yes|YES) ;;
    *)
      echo "Aborted"
      exit 1
      ;;
  esac
fi

rm -rf "$STATE_DIR" "$AUTH_DIR"
mkdir -p "$STATE_DIR" "$AUTH_DIR" "$SECRETS_DIR"
chmod 700 "$STATE_DIR" "$AUTH_DIR" "$SECRETS_DIR" 2>/dev/null || true

echo "Repo-local auth state reset complete."
echo "Next: ./scripts/dev-auth-bootstrap.sh"
