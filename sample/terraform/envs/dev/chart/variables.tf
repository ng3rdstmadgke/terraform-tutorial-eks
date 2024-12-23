locals {
  cluster_name = data.terraform_remote_state.base.outputs.cluster_name
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
}

data terraform_remote_state "base" {
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
  // https://developer.hashicorp.com/terraform/language/state/remote-state-data#argument-reference
  backend = "s3"

  config = {
    // https://developer.hashicorp.com/terraform/language/backend/s3
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "mido/dev/network/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "terraform-tutorial-eks-tfstate-lock"
  }
}