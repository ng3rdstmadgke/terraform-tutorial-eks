variable cluster_name {}
variable vpc_id {}
variable project_dir {}
variable ingress_cidr_blocks {
  // ALBへのアクセスを許可するCIDR
  type = list(string)
  default = ["0.0.0.0/0"]
}

locals {
  namespace = "kube-system"
  service_account = "aws-load-balancer-controller"
  app_version = "v2.11.0"
}
