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
    key    = "dev/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "cloud-infra-automation"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr             = var.vpc_cidr
  environment          = "dev"
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "security_groups" {
  source = "../../modules/security_groups"

  environment       = "dev"
  vpc_id            = module.vpc.vpc_id
  vpc_cidr          = var.vpc_cidr
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}

module "ec2_app" {
  source = "../../modules/ec2"

  environment        = "dev"
  instance_type      = "t3.micro"
  instance_count     = 2
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.app_sg_id]
  key_name           = var.key_name
  root_volume_size   = 20
}

module "ec2_monitoring" {
  source = "../../modules/ec2"

  environment        = "dev"
  instance_type      = "t3.small"
  instance_count     = 1
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.monitoring_sg_id]
  key_name           = var.key_name
  root_volume_size   = 30
}
