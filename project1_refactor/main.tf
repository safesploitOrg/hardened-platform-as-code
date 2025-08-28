terraform {
  required_version = ">= 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.7"
    }
  }
}

# provider "aws" {
#   region = var.aws_region
# }

# MODULES

module "vpc" {
  source              = "./modules/vpc"
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  availability_zone   = var.availability_zone
  project             = var.project
}

module "iam" {
  source  = "./modules/iam"
  project = var.project
}

module "security_group" {
  source      = "./modules/security_group"
  vpc_id      = module.vpc.vpc_id
  allowed_ips = var.allowed_ips
  project     = var.project
}

module "s3" {
  source  = "./modules/s3"
  project = var.project
}

data "aws_caller_identity" "current" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name_pattern]
  }
}


module "cloudtrail" {
  source      = "./modules/cloudtrail"
  project     = var.project
  bucket_name = module.s3.logs_bucket_name
  account_id  = data.aws_caller_identity.current.account_id

  depends_on = [module.s3]  # ensures S3 + its policy are applied first
}

module "ec2" {
  source            = "./modules/ec2"
  ami_id            = data.aws_ami.amazon_linux.id
  instance_type     = var.instance_type
  subnet_id         = module.vpc.public_subnet_id
  security_group_id = module.security_group.security_group_id
  key_name          = module.key_pair.key_name
  instance_profile  = module.iam.instance_profile
  project           = var.project
}

module "key_pair" {
  source     = "./modules/key_pair"
  key_name   = var.key_name
  public_key = var.public_key
}
