#!/bin/bash
set -e

# Update system packages
yum update -y

# Install essential tools
yum install -y \
  python3 \
  python3-pip \
  git \
  wget \
  curl \
  htop \
  amazon-cloudwatch-agent

# Set hostname based on environment
hostnamectl set-hostname ${environment}-app-server

# Start and enable CloudWatch agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

echo "User data initialization complete for environment: ${environment}"
