variable app_name {}
variable stage {}
variable cluster_name {}
variable ingress_cidr_blocks {
  type = list(string)
  default = ["0.0.0.0/0"]
}

data "aws_caller_identity" "self" { }
data "aws_region" "self" {}
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

locals {
  namespace = "kube-system"
  account_id = data.aws_caller_identity.self.account_id
  region = data.aws_region.self.name
  oidc_provider = replace(
    // aws eks describe-cluster --name baseport-prd --output text --query "cluster.identity.oidc.issuer"
    data.aws_eks_cluster.this.identity[0].oidc[0].issuer,
    "https://",
    ""
  )
  vpc_id = data.aws_eks_cluster.this.vpc_config[0].vpc_id
}
