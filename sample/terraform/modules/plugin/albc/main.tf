/**
 * AWS Load Balancer ControllerがALBを作成するために必要なRoleを作成
 *
 * - Install AWS Load Balancer Controller with manifests
 *   https://docs.aws.amazon.com/eks/latest/userguide/lbc-manifest.html
 */
resource "aws_iam_role" "albc" {
  name = "${var.cluster_name}-EKSIngressAWSLoadBalancerControllerRole"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowEksAuthToAssumeRoleForPodIdentity",
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
  })
}

data "http" "albc" {
  // https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http

  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json"
  request_headers = {
    Accept = "application/json"
  }
}

resource "aws_iam_policy" "albc" {
  name   = "${var.cluster_name}-AwsLoadBalancerControllerPolicy"
  policy = data.http.albc.response_body
}

resource "aws_iam_role_policy_attachment" "albc" {
  role = aws_iam_role.albc.name
  policy_arn = aws_iam_policy.albc.arn
}

resource "aws_eks_pod_identity_association" "albc" {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_pod_identity_association

  cluster_name    = var.cluster_name
  namespace       = local.namespace
  service_account = local.service_account
  role_arn        = aws_iam_role.albc.arn
}

/**
 * ALB のセキュリティグループ
 */
resource "aws_security_group" "alb_ingress" {
  name        = "${var.cluster_name}-AlbIngres"
  description = "Allow HTTP, HTTPS access."
  vpc_id      = var.vpc_id

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
    Name = "${var.cluster_name}-AlbIngres"
  }
}

/**
 * ALBCをHelmでインストールするためのvalues.yaml
 */
resource "local_file" "albc_values" {
  filename = "${var.project_dir}/plugin/albc/tmp/values.yaml"
  content = templatefile(
    "${path.module}/values.yaml",
    {
      cluster_name = var.cluster_name
      service_account = local.service_account
      security_group_id = aws_security_group.alb_ingress.id
      role_arn = aws_iam_role.albc.arn
      image_tag = local.app_version
      vpc_id = var.vpc_id
    }
  )
}