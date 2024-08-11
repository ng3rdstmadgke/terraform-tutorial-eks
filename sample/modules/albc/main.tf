/**
 * AWS Load Balancer ControllerがALBを作成するために必要なRoleを作成
 */
resource "aws_iam_role" "aws_loadbalancer_controller" {
  name = "${var.app_name}-${var.stage}-EKSIngressAWSLoadBalancerControllerRole"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17"
    "Statement": {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${local.account_id}:oidc-provider/${local.oidc_provider}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "${local.oidc_provider}:sub": "system:serviceaccount:${local.namespace}:*",
        }
      }
    }
  })
}

resource "aws_iam_policy" "aws_loadbalancer_controller" {
  name   = "${var.cluster_name}-EKSIngressAWSLoadBalancerControllerPolicy"
  // IAMを設定する - ALBCインストール | aws: https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/lbc-manifest.html#lbc-iam
  // 以下のURLの内容
  //   - https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json
  policy = file("${path.module}/albc_iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "aws_loadbalancer_controller" {
  role = aws_iam_role.aws_loadbalancer_controller.name
  policy_arn = aws_iam_policy.aws_loadbalancer_controller.arn
}

// IRSA(IAM Roles for Service Accounts)用のサービスアカウントを作成します。
// https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account
resource "kubernetes_service_account" "aws_loadbalancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = local.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_loadbalancer_controller.arn
    }
  }
}

/**
 * HelmチャートをClusterにインストールします。
 *
 * 参考
 *   - AWS Load Balancer Controller - Helmを使用してインストールする
 *     https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/lbc-helm.html
 *   - AWS Load Balancer Controller
 *     https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/
 */

//helm_release - helm - terraform: https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
resource "helm_release" "aws-load-balancer-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  // CHART VERSIONS
  // 最新バージョン: https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller
  version    = "1.8.1"
  namespace  = local.namespace
  depends_on = [
    kubernetes_service_account.aws_loadbalancer_controller
  ]

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = false
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.ap-northeast-1.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    // APPLICATION VERSION
    // 最新バージョン: https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller
    name  = "image.tag"
    value = "v2.8.1"
  }

  // EKS Fargateを使用する場合は必要
  // https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/lbc-helm.html#lbc-helm-install
  set {
    name  = "region"
    value = local.region
  }

  // EKS Fargateを使用する場合は必要
  // https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/lbc-helm.html#lbc-helm-install
  set {
    name  = "vpcId"
    value = local.vpc_id
  }
}

/**
 * ALB のセキュリティグループ
 */

resource "aws_security_group" "ingress" {
  name        = "${var.app_name}-${var.stage}-AlbIngres"
  description = "Allow HTTP, HTTPS access."
  vpc_id      = local.vpc_id

  ingress {
    description = "Allow HTTP access."
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr_blocks
  }

  ingress {
    description = "Allow HTTPS access."
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr_blocks
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.app_name}-${var.stage}-AlbIngres"
  }
}