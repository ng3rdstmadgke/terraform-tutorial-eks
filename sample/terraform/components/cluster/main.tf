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
 * EKSクラスタ
 */
module cluster {
  source = "../../modules/cluster/eks"
  cluster_name = local.cluster_name
  subnet_ids = local.private_subnet_ids
  access_entries = var.access_entries
}


/**
 * IAMユーザー・ロールにkubernetesAPIへのアクセス権限を付与
 * - EKS アクセスエントリを使用して Kubernetes へのアクセスを IAM ユーザーに許可する | AWS
 *   https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/access-entries.html
 */
resource "aws_eks_access_entry" "admin" {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry
  for_each = toset(var.access_entries)
  cluster_name = local.cluster_name
  principal_arn = each.key
  type = "STANDARD"

  depends_on = [
    module.cluster
  ]
}

resource "aws_eks_access_policy_association" "admin" {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association
  for_each = toset(var.access_entries)
  cluster_name = local.cluster_name
  // アクセスポリシー: https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/access-policies.html#access-policy-permissions
  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.key

  access_scope {
    type = "cluster"
  }

  depends_on = [
    module.cluster
  ]
}