terraform {
  required_version = "~> 1.9.4"

  backend "s3" {
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "mido/dev/cluster/terraform.tfstate"
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


/**
 * EKSクラスタ作成
 *
 * terraform-aws-modules/eks/aws | Terraform
 * https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
 */
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.22.0"

  cluster_name = local.cluster_name
  cluster_version = "1.30"

  // コントロールプレーンにインターネット経由でアクセスする
  cluster_endpoint_public_access = true

  vpc_id = module.vpc.vpc_id

  // ノード/ノードグループがプロビジョニングされるサブネットID
  // control_plane_subnet_idsが省略された場合、コントロールプレーンのENIもこのサブネットにプロビジョニングされる
  subnet_ids = module.vpc.private_subnets

  // IAM Roles for Service Accounts (IRSA) を利用するためのEKS用のOIDCプロバイダを作成する
  enable_irsa = true

  // TerraformをデプロイしたRoleにkubernetesAPIへのアクセス権を付与する (これがないとkubectlコマンドで操作できない)
  enable_cluster_creator_admin_permissions = true

  // IAMユーザー・ロールにKubernetesAPIへのアクセス権限を付与する方式 API or API_AND_CONFIG_MAP
  // https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/grant-k8s-access.html#set-cam
  authentication_mode = "API_AND_CONFIG_MAP"
}

/**
 * IAMユーザー・ロールにkubernetesAPIへのアクセス権限を付与
 * - EKS アクセスエントリを使用して Kubernetes へのアクセスを IAM ユーザーに許可する | AWS
 *   https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/access-entries.html
 */
// aws_eks_access_entry | Terraform
// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry
resource "aws_eks_access_entry" "admin" {
  for_each = toset(var.access_entries)  // 配列はループできないのでセットに変換
  cluster_name      = local.cluster_name
  principal_arn     = each.key
  type              = "STANDARD"

  depends_on = [
    module.eks
  ]
}

// aws_eks_access_policy_association | Terraform
// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association
resource "aws_eks_access_policy_association" "admin" {
  for_each = toset(var.access_entries)
  cluster_name  = local.cluster_name
  // アクセスポリシー: https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/access-policies.html#access-policy-permissions
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.key

  access_scope {
    type       = "cluster"
  }

  depends_on = [
    module.eks
  ]
}