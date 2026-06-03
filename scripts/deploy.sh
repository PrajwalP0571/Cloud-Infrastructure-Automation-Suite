#!/usr/bin/env bash
# deploy.sh — Provision infrastructure and configure all servers
# Usage: ./scripts/deploy.sh [dev|prod]

set -euo pipefail

ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$ROOT_DIR/terraform/environments/$ENVIRONMENT"
ANSIBLE_DIR="$ROOT_DIR/ansible"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

[[ "$ENVIRONMENT" =~ ^(dev|prod)$ ]] || error "Environment must be 'dev' or 'prod'. Got: $ENVIRONMENT"

log "=== Cloud Infrastructure Automation Suite ==="
log "Environment : $ENVIRONMENT"
log "Terraform   : $TERRAFORM_DIR"
log "Ansible     : $ANSIBLE_DIR"
echo ""

# --- Step 1: Terraform ---
log "--- Phase 1: Terraform provisioning ---"
cd "$TERRAFORM_DIR"

log "Initializing Terraform..."
terraform init -upgrade

log "Validating configuration..."
terraform validate

log "Planning changes..."
terraform plan -var-file="terraform.tfvars" -out=tfplan

read -p "Apply Terraform plan? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { log "Aborted by user."; exit 0; }

log "Applying Terraform plan..."
terraform apply tfplan

log "Extracting outputs..."
APP_IPS=$(terraform output -json app_public_ips | jq -r '.[]')
MONITOR_IP=$(terraform output -json monitoring_public_ip | jq -r '.[0]')

log "App server IPs   : $APP_IPS"
log "Monitor server IP: $MONITOR_IP"

# --- Step 2: Update Ansible inventory ---
log "--- Phase 2: Updating Ansible inventory ---"
INVENTORY_FILE="$ANSIBLE_DIR/inventory/hosts.ini"

cat > "$INVENTORY_FILE" <<EOF
[app_servers]
$(echo "$APP_IPS" | awk '{print "app-0"NR" ansible_host="$1" ansible_user=ec2-user"}')

[monitoring]
monitor-01 ansible_host=$MONITOR_IP ansible_user=ec2-user

[all:vars]
ansible_ssh_private_key_file=~/.ssh/${ENVIRONMENT}-key-pair.pem
ansible_python_interpreter=/usr/bin/python3
EOF

log "Inventory updated at $INVENTORY_FILE"

# --- Step 3: Wait for SSH ---
log "--- Phase 3: Waiting for SSH availability ---"
for IP in $APP_IPS $MONITOR_IP; do
  log "Waiting for $IP..."
  for i in $(seq 1 30); do
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
      -i ~/.ssh/${ENVIRONMENT}-key-pair.pem ec2-user@"$IP" "echo ok" \
      2>/dev/null && break
    sleep 10
  done
done

# --- Step 4: Ansible ---
log "--- Phase 4: Ansible configuration ---"
cd "$ANSIBLE_DIR"

log "Testing connectivity..."
ansible all -m ping

log "Running playbook..."
ansible-playbook site.yml -v

log "=== Deployment complete for '$ENVIRONMENT' environment ==="
log "Grafana  : http://$MONITOR_IP:3001  (admin / changeme123)"
log "Prometheus: http://$MONITOR_IP:9090"
