// Amazon EKS ノードの IAM ロール: https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/create-node-role.html#create-worker-node-role
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-${var.node_group_name}-EKSNodeRole"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])
  role = aws_iam_role.eks_node_role.name
  policy_arn = each.key
}

resource "aws_iam_policy" "amazoneks_cni_ipv6_policy" {
  name = "${var.cluster_name}-${var.node_group_name}-AmazonEKS_CNI_IPv6_Policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:AssignIpv6Addresses",
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeInstanceTypes"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:CreateTags"
        ],
        "Resource": [
          "arn:aws:ec2:*:*:network-interface/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "amazoneks_cni_ipv6_policy" {
  role = aws_iam_role.eks_node_role.name
  policy_arn = aws_iam_policy.amazoneks_cni_ipv6_policy.arn
}


resource "aws_launch_template" "node_instance" {
  // 起動テンプレート: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template

  name = "${var.cluster_name}-${var.node_group_name}-EKSNodeLaunchTemplate"

  vpc_security_group_ids = [
    var.cluster_security_group_id,
  ]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 4
      volume_type = "gp3"
      encrypted = true
      delete_on_termination = true
    }
  }
  block_device_mappings {
    device_name = "/dev/xvdb"
    ebs {
      volume_size = 64
      volume_type = "gp3"
      encrypted = true
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.cluster_name}-${var.node_group_name}"
    }
  }

  // base64エンコードされたユーザーデータを指定
  // Bottlerocket Settings Reference: https://bottlerocket.dev/en/os/1.26.x/api/settings/
  user_data = base64encode(templatefile(
    "${path.module}/user-data.ini",
    {
      cluster_name = var.cluster_name
      api_server = var.cluster_api_endpoint
      cluster_certificate =  var.cluster_certificate
    }
  ))
}


resource "aws_eks_node_group" "this" {
  // ノードグループ: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group

  node_group_name = var.node_group_name
  // EKSクラスタ名
  cluster_name    = var.cluster_name
  // Kubernetesバージョン
  version         = var.cluster_version
  // ノードに付与するロール
  node_role_arn   = aws_iam_role.eks_node_role.arn
  // ノードを配置するサブネット
  subnet_ids      = var.cluster_subnet_ids
  // キャパシティタイプ(SPOT, ON_DEMAND)
  capacity_type = "SPOT"  // スポット料金表: https://aws.amazon.com/jp/ec2/spot/pricing/
  // インスタンスタイプ
  instance_types = var.instance_types
  // AMI: https://docs.aws.amazon.com/ja_jp/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType
  ami_type = var.ami_type

  scaling_config {
    desired_size = var.desired_size
    max_size     = 10
    min_size     = 1
  }

  // 起動テンプレートの指定
  launch_template {
    id = aws_launch_template.node_instance.id
    version = aws_launch_template.node_instance.latest_version
  }

  update_config {
    // ノード更新時に利用不可能になるノードの最大数
    max_unavailable = 1
  }

  // ロールは作成済みだけど、ポリシーがアタッチされていない状況が発生するので、depends_on でポリシーのアタッチを待つ
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy,
    aws_iam_role_policy_attachment.amazoneks_cni_ipv6_policy,
  ]
}