terraform {
  required_version = "~> 1.10"

  backend "s3" {
  }

  required_providers {
    // AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82.2"
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

/**
 * Pod Identity Agent
 *
 * - Amazon EKS Pod Identity エージェントのセットアップ
 *   https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/pod-id-agent-setup.html
 */
resource "aws_eks_addon" "eks_pod_identity_agent" {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon

  cluster_name = local.cluster_name
  addon_name   = "eks-pod-identity-agent"
  // バージョンの確認: aws eks describe-addon-versions --addon-name eks-pod-identity-agent
  addon_version = "v1.3.4-eksbuild.1"
}

/**
 * EBS CSI Driver
 *
 * - Amazon EBS で Kubernetes ボリュームを保存する
 *   https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/ebs-csi.html
 */
module ebs_csi_driver {
  source = "../../modules/addon/ebs-csi-driver"
  cluster_name = local.cluster_name
}

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name  = local.cluster_name
  addon_name    = "aws-ebs-csi-driver"
  // バージョンの確認: aws eks describe-addon-versions --addon-name aws-ebs-csi-driver
  addon_version = "v1.37.0-eksbuild.1"
  // Pod Identity に kube-system.ebs-csi-controller-sa に紐づけるIAMロールを指定
  pod_identity_association {
    role_arn = module.ebs_csi_driver.role_arn
    service_account = "ebs-csi-controller-sa"
  }

  depends_on = [ aws_eks_addon.eks_pod_identity_agent ]
}

/**
 * EBS CSI Snapshot Controller
 *
 * - Amazon EKS クラスターでアドオンを活用し、Amazon EBS スナップショットを永続ストレージに使用する
 *   https://aws.amazon.com/jp/blogs/news/using-amazon-ebs-snapshots-for-persistent-storage-with-your-amazon-eks-cluster-by-leveraging-add-ons/
 */
resource "aws_eks_addon" "snapshot_controller" {
  cluster_name  = local.cluster_name
  addon_name    = "snapshot-controller"
  // バージョンの確認: aws eks describe-addon-versions --addon-name snapshot-controller
  addon_version = "v8.1.0-eksbuild.2"
}