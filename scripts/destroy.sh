#!/usr/bin/env bash
# destroy.sh — Tear down infrastructure for a given environment
# Usage: ./scripts/destroy.sh [dev|prod]

set -euo pipefail

ENVIRONMENT=${1:-dev}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="$ROOT_DIR/terraform/environments/$ENVIRONMENT"

log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

[[ "$ENVIRONMENT" =~ ^(dev|prod)$ ]] || error "Environment must be 'dev' or 'prod'."

if [[ "$ENVIRONMENT" == "prod" ]]; then
  echo "⚠️  WARNING: You are about to destroy PRODUCTION infrastructure!"
  read -p "Type 'destroy-prod' to confirm: " confirm
  [[ "$confirm" == "destroy-prod" ]] || { log "Aborted."; exit 0; }
else
  read -p "Destroy '$ENVIRONMENT' environment? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { log "Aborted."; exit 0; }
fi

log "Destroying '$ENVIRONMENT' environment..."
cd "$TERRAFORM_DIR"
terraform destroy -var-file="terraform.tfvars" -auto-approve

log "Environment '$ENVIRONMENT' destroyed."
