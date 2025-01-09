variable cluster_name {
  type = string
  description = "EKSクラスタ名"
}
variable vpc_id {
  type = string
  description = "VPC ID"
}
variable project_dir {
  type = string
  description = "プロジェクトディレクトリの絶対パス"
}
variable ingress_cidr_blocks {
  // ALBへのアクセスを許可するCIDR
  type = list(string)
  default = ["0.0.0.0/0"]
  description = "ALBへのアクセスを許可するCIDR"
}

locals {
  namespace = "kube-system"
  service_account = "aws-load-balancer-controller"
  app_version = "v2.11.0"
}
