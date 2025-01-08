variable cluster_name {}
variable cluster_version {}
variable cluster_security_group_id {}
variable cluster_api_endpoint {}
variable cluster_certificate {}
variable cluster_subnet_ids {}
variable node_group_name {}
variable ami_type {
  type = string
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
  default = ["m6a.large"]
}
variable desired_size {
  type = number
  default = 1
}

data "aws_eks_cluster" "this" {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster
  name = var.cluster_name
}