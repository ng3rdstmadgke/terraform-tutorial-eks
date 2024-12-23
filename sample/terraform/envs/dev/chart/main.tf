terraform {
  required_version = "~> 1.9.4"

  backend "s3" {
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "mido/dev/chart/terraform.tfstate"
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

module albc {
  source = "../../../modules/albc"
  app_name = local.app_name
  stage = local.stage
  cluster_name = local.cluster_name
}

module secret_store_csi_driver {
  source = "../../../modules/secret-store-csi-driver"
}