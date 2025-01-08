terraform {
  required_version = "~> 1.10"

  backend "s3" {
  }

  required_providers {
    // AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82.2"
    }
  }
}

// AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      PROJECT = "TERRAFORM_TUTORIAL_EKS",
    }
  }
}

module keycloak {
  source = "../../modules/service/keycloak"
  cluster_name = local.cluster_name
  cluster_oidc_provider = local.oidc_provider
  cluster_security_group_id = local.cluster_security_group_id
  alb_ingress_sg = local.alb_ingress_sg
  vpc_id = local.vpc_id
  private_subnet_ids = local.private_subnet_ids
  project_dir = local.project_dir
}