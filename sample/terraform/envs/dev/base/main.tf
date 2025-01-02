terraform {
  required_version = "~> 1.10"

  // tfstateファイルをs3で管理する: https://developer.hashicorp.com/terraform/language/settings/backends/s3
  backend "s3" {
    // tfstate保存先のs3バケットとキー
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "mido/dev/base/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    // tfstateファイルのロック情報をDynamoDBで管理する: https://developer.hashicorp.com/terraform/language/settings/backends/s3#dynamodb-state-locking
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
  cluster_name = "tte-mido-dev"
}

output "cluster_name" {
  value = local.cluster_name
}

output "project_dir" {
  value = abspath("${path.module}/../../../..")
}