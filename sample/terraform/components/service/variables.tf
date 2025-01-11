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
  cluster_name = data.terraform_remote_state.base.outputs.cluster_name
  alb_ingress_sg = data.terraform_remote_state.plugin.outputs.alb_ingress_sg
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
  oidc_provider = data.terraform_remote_state.cluster.outputs.oidc_provider
  cluster_security_group_id = data.terraform_remote_state.cluster.outputs.cluster_security_group_id
  project_dir = data.terraform_remote_state.base.outputs.project_dir
}

data "terraform_remote_state" "base" {
  backend = "s3"

  config = {
    region = var.tfstate_region
    bucket = var.tfstate_bucket
    key    = "${var.project_name}/${var.stage}/base/terraform.tfstate"
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    region = var.tfstate_region
    bucket = var.tfstate_bucket
    key    = "${var.project_name}/${var.stage}/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    region = var.tfstate_region
    bucket = var.tfstate_bucket
    key    = "${var.project_name}/${var.stage}/cluster/terraform.tfstate"
  }
}

data "terraform_remote_state" "plugin" {
  backend = "s3"

  config = {
    region = var.tfstate_region
    bucket = var.tfstate_bucket
    key    = "${var.project_name}/${var.stage}/plugin/terraform.tfstate"
  }
}