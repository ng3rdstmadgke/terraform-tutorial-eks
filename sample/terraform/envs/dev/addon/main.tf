terraform {
  required_version = "~> 1.9.4"

  backend "s3" {
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "mido/dev/addon/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "terraform-tutorial-eks-tfstate-lock"
  }

  required_providers {
    // AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.61.0"
    }
  }
}

// AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      PROJECT = "TERRAFORM_TUTORIAL_EKS",
    }
  }
}

locals {
  app_name = "tte-mido"
  stage    = "dev"
  cluster_name = "${local.app_name}-${local.stage}"
}

/**
 * アドオン
 *
 * aws_eks_addon | Terraform
 * https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon
 */
resource "aws_eks_addon" "coredns" {
  cluster_name  = local.cluster_name
  addon_name    = "coredns"
  addon_version = "v1.11.1-eksbuild.8"

  depends_on = [
    module.node_group_1
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = local.cluster_name
  addon_name   = "kube-proxy"
  addon_version = "v1.30.0-eksbuild.3"
  depends_on = [
    module.node_group_1
  ]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = local.cluster_name
  addon_name   = "vpc-cni"
  addon_version = "v1.18.3-eksbuild.1"
  depends_on = [
    module.node_group_1
  ]
}

resource "aws_eks_addon" "eks_pod_identity_agent" {
  cluster_name = local.cluster_name
  addon_name   = "eks-pod-identity-agent"
  addon_version = "v1.3.0-eksbuild.1"
  depends_on = [
    module.node_group_1
  ]
}