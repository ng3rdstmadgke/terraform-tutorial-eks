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

variable tfstate_network_key {
  type = string
  description = "networkコンポーネントのtfstateファイルのパス"
}

variable tfstate_cluster_key {
  type = string
  description = "clusterコンポーネントのtfstateファイルのパス"
}

variable tfstate_plugin_key {
  type = string
  description = "pluginコンポーネントのtfstateファイルのパス"
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
    key    = var.tfstate_base_key
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    region = var.tfstate_region
    bucket = var.tfstate_bucket
    key    = var.tfstate_network_key
  }
}

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    region = var.tfstate_region
    bucket = var.tfstate_bucket
    key    = var.tfstate_cluster_key
  }
}

data "terraform_remote_state" "plugin" {
  backend = "s3"

  config = {
    region = var.tfstate_region
    bucket = var.tfstate_bucket
    key    = var.tfstate_plugin_key
  }
}