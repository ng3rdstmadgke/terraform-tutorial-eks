variable tfstate_bucket {
  type = string
  description = "tfvarsが保存されているバケット"
}

variable tfstate_region {
  type = string
  description = "tfvarsが保存されているバケットのリージョン"
}

variable tfstate_base_key {
  type = string
  description = "baseコンポーネントのtfstateファイルのパス"
}

variable "vpc_cidr" {
  type = string
  description = "VPCのCIDR"
}

variable "private_subnets" {
  type = list(string)
  description = "プライベートサブネットのCIDR"
}

variable "public_subnets" {
  type = list(string)
  description = "パブリックサブネットのCIDR"
}

locals {
  cluster_name = data.terraform_remote_state.base.outputs.cluster_name
}

data terraform_remote_state "base" {
  backend = "s3"

  config = {
    region = var.tfstate_region
    bucket = var.tfstate_bucket
    key    = var.tfstate_base_key
  }
}