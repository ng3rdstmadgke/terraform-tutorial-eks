terraform {
  required_version = "~> 1.10"

  // tfstateファイルをs3で管理する: https://developer.hashicorp.com/terraform/language/settings/backends/s3
  backend "s3" {
    // NOTE: tfstateの保存先情報は terraform init 時に変数ファイル(terraform/components/tfvars/dev.backend.tfvars) で指定します。
  }

  required_providers {
    // AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82.2"
    }
  }
}

output "cluster_name" {
  value = "${var.project_name}-${var.stage}"
}

output "project_dir" {
  value = abspath("${path.module}/../../..")
}