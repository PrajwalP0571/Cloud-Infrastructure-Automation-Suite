terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "cloud-infra-automation-tfstate"
    key    = "prod/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "cloud-infra-automation"
      Environment = "prod"
      ManagedBy   = "Terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr             = var.vpc_cidr
  environment          = "prod"
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "security_groups" {
  source = "../../modules/security_groups"

  environment       = "prod"
  vpc_id            = module.vpc.vpc_id
  vpc_cidr          = var.vpc_cidr
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}

module "ec2_app" {
  source = "../../modules/ec2"

  environment        = "prod"
  instance_type      = "t3.medium"
  instance_count     = 3
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.app_sg_id]
  key_name           = var.key_name
  root_volume_size   = 30
  alarm_sns_arn      = var.alarm_sns_arn
}

module "ec2_monitoring" {
  source = "../../modules/ec2"

  environment        = "prod"
  instance_type      = "t3.medium"
  instance_count     = 1
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.monitoring_sg_id]
  key_name           = var.key_name
  root_volume_size   = 50
}
