locals {
  cluster_name = data.terraform_remote_state.base.outputs.cluster_name
  account_id = data.aws_caller_identity.this.account_id
  aws_region = data.aws_region.this.name
  namespace = "keycloak"
  service_account = "keycloak"
  db_user = "admin"
  db_name = "keycloak"
  oidc_provider = replace(
    // AWS CLIで確認する場合: aws eks describe-cluster --name クラスタ名 --output text --query "cluster.identity.oidc.issuer"
    data.aws_eks_cluster.this.identity[0].oidc[0].issuer,
    "https://",
    ""
  )
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


data "aws_caller_identity" "this" {}

data "aws_region" "this" {}

// aws_eks_cluster: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster
data "aws_eks_cluster" "this" {
  name = local.cluster_name
}

// aws_eks_cluster_auth: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth
data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
}
