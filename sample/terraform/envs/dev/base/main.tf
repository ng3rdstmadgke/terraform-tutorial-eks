terraform {
  required_version = "~> 1.9.4"

  backend "s3" {
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "mido/dev/base/terraform.tfstate"
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

locals {
  app_name = "tte-mido"
  stage    = "dev"
  cluster_name = "${local.app_name}-${local.stage}"
}

output "app_name" {
  value = local.app_name
}

output "stage" {
  value = local.stage
}

output "cluster_name" {
  value = local.cluster_name
}