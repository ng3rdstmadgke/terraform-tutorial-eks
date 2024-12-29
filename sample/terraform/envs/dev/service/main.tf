terraform {
  required_version = "~> 1.10"

  backend "s3" {
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "mido/dev/service/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "terraform-tutorial-eks-tfstate-lock"
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
  source = "../../../modules/keycloak"
  cluster_name = data.terraform_remote_state.base.outputs.cluster_name
  alb_ingress_sg = data.terraform_remote_state.plugin.outputs.alb_ingress_sg
}