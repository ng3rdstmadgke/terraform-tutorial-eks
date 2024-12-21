terraform {
  required_version = "~> 1.9.4"

  backend "s3" {
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "mido/dev/node-group/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "terraform-tutorial-eks-tfstate-lock"
  }

  required_providers {
    // AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.61.0"
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

locals {
  app_name = "tte-mido"
  stage    = "dev"
  cluster_name = "${local.app_name}-${local.stage}"
}


/**
 * ノードグループ
 */
module node_group_1 {
  source = "../../../modules/node-group"
  app_name = local.app_name
  stage = local.stage
  node_group_name = "ng-1"
  // スポット料金: https://aws.amazon.com/jp/ec2/spot/pricing/
  instance_types = ["t3a.xlarge", "t3a.large", "t3a.medium", "t3.xlarge", "t3.large", "t3.medium"]
  desired_size = 1

  depends_on = [
    module.eks
  ]
}
