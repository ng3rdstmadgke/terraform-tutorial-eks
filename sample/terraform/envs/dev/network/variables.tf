locals {
  cluster_name = data.terraform_remote_state.base.outputs.cluster_name
  vpc_cidr = "10.60.0.0/16"
  private_subnets = [
    "10.60.1.0/24",
    "10.60.2.0/24",
    "10.60.3.0/24",
  ]
  public_subnets = [
    "10.60.101.0/24",
    "10.60.102.0/24",
    "10.60.103.0/24",
  ]
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