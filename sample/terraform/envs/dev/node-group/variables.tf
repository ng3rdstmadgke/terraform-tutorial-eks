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
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "mido/dev/cluster/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "terraform-tutorial-eks-tfstate-lock"
  }
}