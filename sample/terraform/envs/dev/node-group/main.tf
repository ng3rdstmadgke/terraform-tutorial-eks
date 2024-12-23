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
  source = "../../../modules/node-group-bottlerocket"
  cluster_name = local.cluster_name
  node_group_name = "ng-bottlerocket-1"
  ami_type = "BOTTLEROCKET_x86_64"
  instance_types = ["t3a.xlarge", "t3a.large", "t3a.medium"] // スポット料金: https://aws.amazon.com/jp/ec2/spot/pricing/
  desired_size = 1
}
