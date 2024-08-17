locals {
  app_name = "tutorial-mido"
  stage    = "dev"
  cluster_name = "${local.app_name}-${local.stage}"
}

// EKSクラスタの参照を取得
// aws_eks_cluster: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster
data "aws_eks_cluster" "this" {
  name = local.cluster_name
}

// EKS クラスターと通信するための認証トークンを取得
// aws_eks_cluster_auth: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth
data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
}
