variable project_name {
  type = string
  description = "プロジェクト名"
}

variable stage {
  type = string
  description = "ステージ名"
}

variable tfstate_bucket {
  type = string
  description = "tfvarsが保存されているバケット"
}

variable tfstate_region {
  type = string
  description = "tfvarsが保存されているバケットのリージョン"
}

locals {
  cluster_name = data.terraform_remote_state.cluster.outputs.cluster_name
  cluster_version = data.terraform_remote_state.cluster.outputs.version
  cluster_security_group_id = data.terraform_remote_state.cluster.outputs.cluster_security_group_id
  cluster_api_endpoint = data.terraform_remote_state.cluster.outputs.api_endpoint
  cluster_certificate = data.terraform_remote_state.cluster.outputs.cluster_certificate
  cluster_subnet_ids = data.terraform_remote_state.cluster.outputs.subnet_ids
}

data terraform_remote_state "cluster" {
  backend = "s3"

  config = {
    region = var.tfstate_region
    bucket = var.tfstate_bucket
    key    = "${var.project_name}/${var.stage}/cluster/terraform.tfstate"
  }
}