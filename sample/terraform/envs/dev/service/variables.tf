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
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "mido/dev/base/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "terraform-tutorial-eks-tfstate-lock"
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "mido/dev/network/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "terraform-tutorial-eks-tfstate-lock"
  }
}

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "mido/dev/cluster/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "terraform-tutorial-eks-tfstate-lock"
  }
}

data "terraform_remote_state" "plugin" {
  backend = "s3"

  config = {
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "mido/dev/plugin/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "terraform-tutorial-eks-tfstate-lock"
  }
}