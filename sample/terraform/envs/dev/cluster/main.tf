terraform {
  required_version = "~> 1.9.4"

  backend "s3" {
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "ubuntu/dev/cluster/terraform.tfstate"
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

provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      PROJECT = "TERRAFORM_TUTORIAL_EKS",
    }
  }
}

/**
 * VPC作成
 *
 * terraform-aws-modules/vpc/aws | Terraform
 * https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
 */
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8.1"

  name = "${local.app_name}-${local.stage}-vpc"
  cidr = local.vpc_cidr

  azs             = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  // パブリックサブネットを外部LB用に利用することをKubernetesとALBが認識できるようにするためのタグ
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  // プライベートネットを内部LB用に利用することをKubernetesとALBが認識できるようにするためのタグ
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
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
  for_each = toset(var.access_entries)
  cluster_name      = local.cluster_name
  principal_arn     = each.key
  type              = "STANDARD"
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
}

/**
 * ノードグループ
 */
module node_group_1 {
  source = "../../../modules/node-group"
  app_name = local.app_name
  stage = local.stage
  node_group_name = "ng-1"
  // スポット料金: https://aws.amazon.com/jp/ec2/spot/pricing/
  instance_types = ["t3a.xlarge"]
  desired_size = 1
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