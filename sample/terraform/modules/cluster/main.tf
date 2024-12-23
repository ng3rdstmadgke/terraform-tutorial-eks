/**
 * EKSクラスタ
 *
 * NOTE:
 * EKS Auto Mode 利用時は以下の3つの設定がすべて true でなければならない。逆に無効にする場合はすべて false でなければならない
 * - compute_config.enabled
 * - storage_config.block_storage.enabled
 * - kubernetes_network_config.elastic_load_balancing.enabled
 */
resource "aws_eks_cluster" "this" {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster

  name = local.cluster_name

  role_arn = aws_iam_role.cluster_role.arn

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    // TerraformをデプロイしたRoleにkubernetesAPIへのアクセス権を付与する
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    // EKSのプライベートAPIエンドポイントの有効化
    endpoint_private_access = true
    // EKSのパブリックAPIエンドポイントの有効化
    endpoint_public_access = true
    // パブリックAPIエンドポイントにアクセス可能なネットワーク
    public_access_cidrs = [
      "0.0.0.0/0"
    ]
    // コントロールプレーンとワーカーノード間の通信を許可するためのSG
    security_group_ids = []
    // ワーカーノードが配置されるサブネット (コントロールプレーンとの通信のため、cross-account ENIが作成される)
    subnet_ids = var.subnet_ids
  }

  kubernetes_network_config {
    // KubernetesのPodとServiceに割り当てられるIPのファミリー (ipv4 or ipv6)
    ip_family = "ipv4"
    // KubernetesポッドとサービスのIPアドレスを割り当てるCIDRブロック (変更不可)
    // VPCピアリングやTGWで接続されている他のネットワークリソースと重複しないブロックを指定しなければならない。
    // 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 のブロックの中から指定
    service_ipv4_cidr = "172.20.0.0/16"

    // EKS Auto Mode 利用時のロードバランシング機能の設定
    elastic_load_balancing {
      enabled = false
    }
  }

  // vpc-cni, kube-proxy, corednsといったアドオンを管理対象外のアドオンとしてクラスタ作成時にインストールするか
  // NOTE: この値を変更すると新しいクラスタが強制的に作成されるので注意
  bootstrap_self_managed_addons = true

  // CloudWatchLogsに出力するコントロールプレーンのログ設定: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  enabled_cluster_log_types = [ "api", "audit", "authenticator", "controllerManager", "scheduler" ]


  // 指定したKMSのキーでetcdに保存されているKubernetesのリソースを暗号化する
  encryption_config {
    provider {
      key_arn = aws_kms_key.kubernetes_encription.arn
    }
    // 暗号化するリソース
    resources = [ "secrets" ]
  }

  // クラスタのアップデートポリシー
  upgrade_policy {
    // STANDARD: 標準サポート終了時に自動的にアップグレード
    // EXTENDED: 標準サポート終了時に拡張サポートに入る
    support_type = "EXTENDED"
  }

  // Kubernetesのバージョン
  version = "1.31"

  // ゾーンシフト (障害時などに対象のAZを切り離す機能)
  zonal_shift_config {
    enabled = false
  }

  // EKS Auto Mode 利用時のcomputeの設定
  compute_config {
    enabled = false
  }
  // EKS Auto Mode 利用時のストレージ設定
  storage_config {
    block_storage {
      enabled = false
    }
  }

  // Hybrid Nodes利用時の設定
  // remote_network_config {}

  depends_on = [
    aws_cloudwatch_log_group.eks_control_plane
  ]
}

/**
 * クラスターロール
 */
resource "aws_iam_role" "cluster_role" {
  name = "${var.app_name}-${var.stage}-EKSClusterRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Sid       = "EKSClusterAssumeRole"
        Action    = [ "sts:TagSession", "sts:AssumeRole" ]
        Effect    = "Allow"
        Principal = { Service = "eks.amazonaws.com" }
      }
    ]
  })
}

// aws管理ポリシー
resource "aws_iam_role_policy_attachment" "aws_managed_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSComputePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
  ])
  role = aws_iam_role.cluster_role.name
  policy_arn = each.key
}


// etcdに保存されたKubernetesシークレットの暗号化に利用するKMSの操作権限
resource "aws_iam_policy" "secret_encription_policy" {
  name = "${var.app_name}-${var.stage}-SecretEncriptionPolicy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ListGrants",
          "kms:DescribeKey"
        ],
        "Resource": aws_kms_key.kubernetes_encription.arn,
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "secret_encription_policy" {
  role = aws_iam_role.cluster_role.name
  policy_arn = aws_iam_policy.secret_encription_policy.arn
}


/**
 * Kubernetesのリソースを暗号化するためのKMSキー
 */
resource "aws_kms_key" "kubernetes_encription" {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key

  description = "${var.app_name}-${var.stage} cluster encryption key"
  is_enabled = true
  key_usage = "ENCRYPT_DECRYPT"
  multi_region = false
  // キーローテーションの設定
  enable_key_rotation = true
  rotation_period_in_days = 365
  // 暗号化と復号化を行うため対象キーでなければならない
  // キー仕様リファレンス: https://docs.aws.amazon.com/ja_jp/kms/latest/developerguide/symm-asymm-choose-key-spec.html
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  policy = jsonencode(
    {
      Statement = [
        {
          Sid     = "Default"
          Effect  = "Allow"
          Principal = {
            AWS = "arn:aws:iam::${local.account_id}:root"
          }
          Action  = "kms:*"
          Resource  = "*"
        },
        {
          Sid     = "KeyAdministration"
          Effect  = "Allow"
          Principal = {
            AWS = var.access_entries
          }
          Action  = [
            "kms:Update*",
            "kms:UntagResource",
            "kms:TagResource",
            "kms:ScheduleKeyDeletion",
            "kms:Revoke*",
            "kms:ReplicateKey",
            "kms:Put*",
            "kms:List*",
            "kms:ImportKeyMaterial",
            "kms:Get*",
            "kms:Enable*",
            "kms:Disable*",
            "kms:Describe*",
            "kms:Delete*",
            "kms:Create*",
            "kms:CancelKeyDeletion",
          ]
          Resource  = "*"
        },
        {
          Sid     = "KeyUsage"
          Effect  = "Allow"
          Principal = {
            AWS = aws_iam_role.cluster_role.arn
          }
          Action  = [
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:Encrypt",
            "kms:DescribeKey",
            "kms:Decrypt",
          ]
          Resource  = "*"
        },
      ]
      Version   = "2012-10-17"
    }
  )
}

resource "aws_kms_alias" "kubernetes_encription" {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias

  name = "alias/eks/${local.cluster_name}"
  target_key_id = aws_kms_key.kubernetes_encription.key_id
}

/**
 * IRSAを利用するため、IAMにEKSのOIDCプロバイダを登録
 * 
 * EKSの認証・認可の仕組み解説 | Zenn: https://zenn.dev/take4s5i/articles/aws-eks-authentication#iam-roles-for-service-accounts(irsa)
 */
resource "aws_iam_openid_connect_provider" "default" {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com",
  ]
}



 /**
  * コントロールプレーンのログを保存するロググループ
  *
  * ロググループ名は /aws/eks/{MY_CLUSTER}/cluster で固定
  * 参考: https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/control-plane-logs.html
  *
  */
resource "aws_cloudwatch_log_group" "eks_control_plane" {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group

  name = "/aws/eks/${local.cluster_name}/cluster"

  // ログの保持期間
  retention_in_days = 30

  tags = {
    Name = "/aws/eks/${local.cluster_name}/cluster"
  }
}
