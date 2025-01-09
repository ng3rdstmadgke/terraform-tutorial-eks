variable cluster_name {
  type = string
  description = "EKSクラスタ名"
}
variable cluster_version {
  type = string
  description = "Kubernetesバージョン"
}
variable cluster_security_group_id {
  type = string
  description = "EKSクラスタのクラスタセキュリティグループID"
}
variable cluster_api_endpoint {
  type = string
  description = "EKSクラスタのAPIエンドポイント"
}
variable cluster_certificate {
  type = string
  description = "EKSクラスタの証明書"
}
variable cluster_subnet_ids {
  type = list(string)
  description = "EKSクラスタのサブネットID"
}
variable node_group_name {
  type = string
  description = "ノードグループ名"
}
variable ami_type {
  type = string
  description = "ノードのAMIタイプ"
  validation {
    condition = contains([
      "BOTTLEROCKET_ARM_64",
      "BOTTLEROCKET_x86_64",
      "BOTTLEROCKET_ARM_64_NVIDIA",
      "BOTTLEROCKET_x86_64_NVIDIA",
    ], var.ami_type)
    error_message = "Invalid AMI type. Please specify one of the following: BOTTLEROCKET_ARM_64, BOTTLEROCKET_x86_64, BOTTLEROCKET_ARM_64_NVIDIA, BOTTLEROCKET_x86_64_NVIDIA"
  }
}
variable instance_types {
  type = list(string)
  description = "ノードのインスタンスタイプ"
  default = ["m6a.large"]
}
variable desired_size {
  type = number
  description = "起動するノード数"
  default = 1
}

data "aws_eks_cluster" "this" {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster
  name = var.cluster_name
}