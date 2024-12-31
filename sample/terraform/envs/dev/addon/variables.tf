locals {
  cluster_name = data.terraform_remote_state.cluster.outputs.cluster_name
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
