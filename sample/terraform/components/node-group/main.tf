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


/**
 * ノードグループ
 */
module node_group_bottlerocket_1 {
  source = "../../modules/node-group/bottlerocket"
  cluster_name = local.cluster_name
  cluster_version = local.cluster_version
  cluster_security_group_id = local.cluster_security_group_id
  cluster_api_endpoint = local.cluster_api_endpoint
  cluster_certificate = local.cluster_certificate
  cluster_subnet_ids = local.cluster_subnet_ids
  node_group_name = "ng-bottlerocket-1"
  ami_type = "BOTTLEROCKET_x86_64"
  instance_types = ["t3a.xlarge", "t3a.large", "t3a.medium"] // スポット料金: https://aws.amazon.com/jp/ec2/spot/pricing/
  desired_size = 1
}
