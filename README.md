# Cloud Infrastructure Automation Suite

> Multi-environment AWS infrastructure provisioned with **Terraform**, configured with **Ansible**, and monitored in real time via **Prometheus** and **Grafana**.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Configure AWS Credentials](#2-configure-aws-credentials)
  - [3. Deploy Dev Environment](#3-deploy-dev-environment)
  - [4. Deploy Prod Environment](#4-deploy-prod-environment)
- [Terraform — Infrastructure Provisioning](#terraform--infrastructure-provisioning)
  - [Module: VPC](#module-vpc)
  - [Module: EC2](#module-ec2)
  - [Module: Security Groups](#module-security-groups)
  - [Environments](#environments)
- [Ansible — Configuration Management](#ansible--configuration-management)
  - [Roles](#roles)
  - [Running Playbooks](#running-playbooks)
- [Monitoring Stack](#monitoring-stack)
  - [Prometheus](#prometheus)
  - [Grafana](#grafana)
  - [Alert Rules](#alert-rules)
- [Deployment Scripts](#deployment-scripts)
- [Environment Comparison](#environment-comparison)
- [Key Design Decisions](#key-design-decisions)
- [Troubleshooting](#troubleshooting)

---

## Overview

This project automates the full lifecycle of AWS cloud infrastructure — from VPC creation to application server configuration to real-time observability — using industry-standard IaC and configuration management tools.

**What it does:**

- Provisions isolated **dev** and **prod** AWS environments using reusable Terraform modules
- Configures all EC2 instances via Ansible roles (baseline hardening, Node Exporter)
- Deploys a dedicated monitoring server running Prometheus + Grafana
- Scrapes system metrics from all app servers via Node Exporter
- Fires alerts when CPU, memory, or disk thresholds are breached
- Stores Terraform state remotely in S3 for team collaboration

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS VPC (10.0.0.0/16)                │
│                                                             │
│   ┌──────────────────────┐   ┌──────────────────────────┐  │
│   │   Public Subnet 1a   │   │   Public Subnet 1b       │  │
│   │                      │   │                          │  │
│   │  ┌────────────────┐  │   │  ┌────────────────────┐  │  │
│   │  │  App Server 1  │  │   │  │   App Server 2     │  │  │
│   │  │  (Node Exp.)   │  │   │  │   (Node Exp.)      │  │  │
│   │  └───────┬────────┘  │   │  └─────────┬──────────┘  │  │
│   └──────────│───────────┘   └────────────│─────────────┘  │
│              │                            │                 │
│              └──────────────┬─────────────┘                 │
│                             │  scrape :9100                 │
│                    ┌────────▼────────┐                      │
│                    │ Monitor Server  │                      │
│                    │  Prometheus     │ :9090                │
│                    │  Grafana        │ :3001                │
│                    └─────────────────┘                      │
│                                                             │
│   ┌──────────────────────────────────────────────────────┐  │
│   │              Private Subnets (future use)            │  │
│   └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                       Internet Gateway
                              │
                         Internet
```

---

## Tech Stack

| Category | Tool | Version | Purpose |
|---|---|---|---|
| Cloud | AWS | — | EC2, S3, VPC, IAM, CloudWatch |
| IaC | Terraform | >= 1.3.0 | Infrastructure provisioning |
| Config Mgmt | Ansible | >= 2.14 | Server configuration |
| Metrics | Prometheus | 2.50.0 | Metrics collection & alerting |
| Dashboards | Grafana | Latest | Metrics visualization |
| Monitoring Agent | Node Exporter | 1.7.0 | System metrics on each host |
| Scripting | Bash | — | Deployment automation |
| State Backend | AWS S3 | — | Remote Terraform state |

---

## Project Structure

```
cloud-infrastructure-automation-suite/
│
├── terraform/
│   ├── modules/
│   │   ├── vpc/                  # VPC, subnets, route tables, IGW
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── ec2/                  # EC2 instances, IAM roles, CloudWatch alarms
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── user_data.sh.tpl
│   │   └── security_groups/      # App and monitoring security groups
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── environments/
│       ├── dev/                  # Dev environment (t3.micro, 2 instances)
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   └── terraform.tfvars
│       └── prod/                 # Prod environment (t3.medium, 3 instances)
│           ├── main.tf
│           └── variables.tf
│
├── ansible/
│   ├── ansible.cfg
│   ├── site.yml                  # Master playbook
│   ├── inventory/
│   │   └── hosts.ini             # Generated by deploy.sh
│   └── roles/
│       ├── common/               # OS baseline, packages, sysctl
│       │   └── tasks/main.yml
│       └── monitoring/           # Prometheus, Grafana, Node Exporter
│           ├── tasks/main.yml
│           ├── handlers/main.yml
│           ├── defaults/main.yml
│           └── templates/
│               ├── prometheus.yml.j2
│               ├── prometheus.service.j2
│               ├── node_exporter.service.j2
│               └── grafana.ini.j2
│
├── monitoring/
│   ├── prometheus/
│   │   └── alerts.yml            # CPU, memory, disk, instance-down rules
│   └── grafana/
│       └── dashboards/
│           └── node_overview.json
│
├── scripts/
│   ├── deploy.sh                 # Full pipeline: Terraform → Ansible
│   └── destroy.sh                # Safe environment teardown
│
├── .gitignore
└── README.md
```

---

## Prerequisites

| Requirement | Install Guide |
|---|---|
| Terraform >= 1.3.0 | [terraform.io/downloads](https://developer.hashicorp.com/terraform/downloads) |
| Ansible >= 2.14 | `pip3 install ansible` |
| AWS CLI v2 | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |
| jq | `yum install jq` / `brew install jq` |
| AWS account with IAM permissions | EC2, VPC, S3, IAM, CloudWatch |

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/PrajwalP0571/Cloud-Infrastructure-Automation-Suite.git
cd Cloud-Infrastructure-Automation-Suite
```

### 2. Configure AWS Credentials

```bash
aws configure
# Enter: AWS Access Key ID, Secret Access Key, Region (ap-south-1), Output (json)
```

Create the S3 bucket for Terraform state (one-time setup):

```bash
aws s3api create-bucket \
  --bucket cloud-infra-automation-tfstate \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws s3api put-bucket-versioning \
  --bucket cloud-infra-automation-tfstate \
  --versioning-configuration Status=Enabled
```

### 3. Deploy Dev Environment

```bash
# Full automated deployment (Terraform + Ansible)
chmod +x scripts/deploy.sh
./scripts/deploy.sh dev
```

The script will:
1. Run `terraform init`, `plan`, and `apply` for the dev environment
2. Auto-generate the Ansible inventory from Terraform outputs
3. Wait for SSH to become available on all instances
4. Run the Ansible playbook to configure all servers
5. Print the Grafana and Prometheus URLs on completion

### 4. Deploy Prod Environment

```bash
./scripts/deploy.sh prod
```

> ⚠️ Prod requires explicit confirmation. Ensure `allowed_ssh_cidrs` is restricted (not `0.0.0.0/0`) before production use.

---

## Terraform — Infrastructure Provisioning

### Module: VPC

Creates an isolated network environment per deployment stage.

**Resources created:**
- VPC with DNS support enabled
- 2 public subnets across separate availability zones
- 2 private subnets (reserved for future DB/backend use)
- Internet Gateway
- Public route table with association

**Key variables:**

| Variable | Dev Default | Prod Default |
|---|---|---|
| `vpc_cidr` | `10.0.0.0/16` | `10.1.0.0/16` |
| `availability_zones` | 2 AZs | 3 AZs |

### Module: EC2

Provisions application and monitoring servers with IAM roles and CloudWatch alarms.

**Resources created:**
- EC2 instances (count configurable per environment)
- IAM role with SSM and CloudWatch Agent policies
- IAM instance profile attached to each instance
- CloudWatch CPU alarms (threshold: 80%)
- Encrypted gp3 EBS root volumes
- User data bootstrap script

**Key variables:**

| Variable | Dev | Prod |
|---|---|---|
| `instance_type` | `t3.micro` | `t3.medium` |
| `instance_count` | `2` | `3` |
| `root_volume_size` | `20 GB` | `30 GB` |

### Module: Security Groups

**App servers allow:**
- SSH (port 22) — restricted to `allowed_ssh_cidrs`
- HTTP/HTTPS (80, 443) — public
- Node Exporter (9100) — VPC-internal only
- App port (3000) — public

**Monitoring server allows:**
- SSH (22) — restricted
- Prometheus UI (9090) — restricted
- Grafana UI (3001) — restricted

### Environments

Each environment directory (`dev/`, `prod/`) is a fully self-contained root module that calls all three shared modules with environment-specific variable values. They use separate S3 state keys so dev and prod states are completely isolated.

---

## Ansible — Configuration Management

### Roles

#### `common`

Applied to **all hosts**. Establishes a secure, consistent baseline:

- Updates all system packages
- Installs utilities: git, wget, curl, htop, python3
- Sets timezone to `Asia/Kolkata`
- Tunes sysctl parameters (somaxconn, swappiness)
- Configures logrotate for application logs

#### `monitoring`

Applied to **all hosts** but uses `when: "'group_name' in group_names"` conditionals to install the right components per host type:

- **App servers**: Node Exporter only (exposes system metrics on port 9100)
- **Monitoring server**: Node Exporter + Prometheus + Grafana

Prometheus configuration is generated from a Jinja2 template that dynamically inserts all app server IPs from the Ansible inventory — no manual target configuration needed.

### Running Playbooks

```bash
cd ansible/

# Test connectivity to all hosts
ansible all -m ping

# Dry run (check mode — no changes applied)
ansible-playbook site.yml --check

# Run full playbook
ansible-playbook site.yml -v

# Run only the monitoring role
ansible-playbook site.yml --tags monitoring

# Target a specific host group
ansible-playbook site.yml --limit app_servers
```

---

## Monitoring Stack

### Prometheus

Scrapes metrics from all Node Exporter instances every **15 seconds**.

**Access:** `http://<monitor-ip>:9090`

Useful queries to try in the Prometheus UI:

```promql
# CPU usage per instance
100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage %
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))

# Disk usage on root mount
100 - ((node_filesystem_avail_bytes{mountpoint="/"} * 100) / node_filesystem_size_bytes{mountpoint="/"})

# Network receive rate
rate(node_network_receive_bytes_total[5m])
```

### Grafana

**Access:** `http://<monitor-ip>:3001`  
**Default credentials:** `admin / changeme123`

The **Node Overview** dashboard (`monitoring/grafana/dashboards/node_overview.json`) includes:

| Panel | Type | Metric |
|---|---|---|
| CPU Usage % | Gauge | `node_cpu_seconds_total` |
| Memory Usage % | Gauge | `node_memory_MemAvailable_bytes` |
| Disk Usage % | Stat | `node_filesystem_avail_bytes` |
| Network I/O | Time series | `node_network_*_bytes_total` |

To import the dashboard: Grafana → Dashboards → Import → Upload JSON file.

### Alert Rules

Defined in `monitoring/prometheus/alerts.yml`:

| Alert | Condition | Severity | Duration |
|---|---|---|---|
| `HighCPUUsage` | CPU > 80% | warning | 5 min |
| `CriticalCPUUsage` | CPU > 95% | critical | 2 min |
| `HighMemoryUsage` | Memory > 85% | warning | 5 min |
| `DiskSpaceLow` | Disk > 80% | warning | 10 min |
| `InstanceDown` | `up == 0` | critical | 1 min |

---

## Deployment Scripts

### `scripts/deploy.sh`

Full end-to-end deployment in a single command.

```
Usage: ./scripts/deploy.sh [dev|prod]
```

**What it does, in order:**
1. Runs `terraform init`, `validate`, `plan`
2. Prompts for confirmation before `apply`
3. Extracts instance IPs from Terraform outputs
4. Regenerates the Ansible inventory dynamically
5. Polls SSH until all instances are reachable
6. Runs the full Ansible playbook
7. Prints access URLs for Grafana and Prometheus

### `scripts/destroy.sh`

Safe teardown with environment-aware confirmation.

```
Usage: ./scripts/destroy.sh [dev|prod]
```

> Destroying `prod` requires typing `destroy-prod` explicitly to prevent accidental teardown.

---

## Environment Comparison

| Property | Dev | Prod |
|---|---|---|
| VPC CIDR | `10.0.0.0/16` | `10.1.0.0/16` |
| App instance type | `t3.micro` | `t3.medium` |
| App instance count | 2 | 3 |
| Availability zones | 2 | 3 |
| Monitoring disk | 30 GB | 50 GB |
| SSH CIDR | Open (dev) | VPC-internal only |
| SNS alerts | Disabled | Configurable |

---

## Key Design Decisions

**Why separate Terraform environments instead of workspaces?**  
Using separate directories for `dev/` and `prod/` provides stronger isolation — different state files, different variable files, and no risk of a workspace switch accidentally targeting production. It also makes CI/CD pipelines simpler to reason about.

**Why Ansible over user data scripts?**  
User data runs only once at instance launch. Ansible playbooks are idempotent and re-runnable — if a configuration drifts or a new server is added, the same playbook brings it into compliance without reprovisioning.

**Why Node Exporter over CloudWatch Agent alone?**  
CloudWatch Agent provides AWS-native metrics but Prometheus + Grafana gives a unified, self-hosted observability stack that works identically across any cloud or on-premises environment — a more transferable and interview-relevant design.

**Why dynamic Ansible inventory from Terraform outputs?**  
Hardcoding IPs in inventory files breaks every time infrastructure is re-provisioned. The deploy script extracts IPs from Terraform outputs and regenerates the inventory automatically, keeping the pipeline fully reproducible.

---

## Troubleshooting

**`terraform init` fails with S3 backend error**  
Ensure the S3 bucket exists and your IAM user has `s3:GetObject`, `s3:PutObject`, and `s3:ListBucket` permissions on it.

**Ansible `ping` fails after deploy**  
Check that the security group allows SSH on port 22 from your IP. Also confirm the correct `.pem` key path in `ansible.cfg` and `hosts.ini`.

**Prometheus shows no targets**  
Verify Node Exporter is running on app servers: `systemctl status node_exporter`. Check that port 9100 is open in the app security group for the VPC CIDR.

**Grafana shows "No data"**  
Add Prometheus as a data source in Grafana: Settings → Data Sources → Add → Prometheus → URL: `http://localhost:9090`. Then re-import the dashboard JSON.
