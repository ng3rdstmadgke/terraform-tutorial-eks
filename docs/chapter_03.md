Chapter3 Helmでチャートをインストール
---
[READMEに戻る](../README.md)


# ■ 作るもの

この章ではEKSクラスタに下記のチャートをHelmでインストールします。

- aws-load-balancer-controller
- metrics-server
- secrets-store-csi-driver
- secrets-store-csi-driver-provider-aws


# ■ 変数の設定

`terraform/envs/dev/charts/variables.tf`

```hcl
locals {
  app_name = "xxxxx"  # EDIT: clusterのlocal.app_nameで指定した値を指定してください
  stage    = "dev"
  cluster_name = "${local.app_name}-${local.stage}"
}

// EKSクラスタの参照を取得
// aws_eks_cluster: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster
data "aws_eks_cluster" "this" {
  name = local.cluster_name
}

// EKS クラスターと通信するための認証トークンを取得
// aws_eks_cluster_auth: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth
data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
}

```

# ■ プロバイダの設定

この章ではAWSプロバイダのほかに、[Kubernetesプロバイダ](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)と[Helmプロバイダ](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)を利用するので、それぞれのプロバイダをセットアップしていきます。


`terraform/envs/dev/charts/main.tf`

```hcl
terraform {
  required_version = "~> 1.9.4"

  backend "s3" {
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "xxxxxx/dev/chart/terraform.tfstate"  // EDIT: clusterで指定した値を指定してください
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
    // Kubernetes Provider: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31.0"
    }
    // Helm Provider: https://registry.terraform.io/providers/hashicorp/helm/latest/docs
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14.0"
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

// Kubernetes Provider: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
provider "kubernetes" {
  // kubenetesAPIのホスト名(URL形式)。KUBE_HOST環境変数で指定している値に基づく。
  host                   = data.aws_eks_cluster.this.endpoint
  // TLS認証用のPEMエンコードされたルート証明書のバンドル
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

// Helm Provider: https://registry.terraform.io/providers/hashicorp/helm/latest/docs
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
```

# ■ aws-load-balancer-controller をインストール

## モジュールの定義

aws-load-balancer-controller をインストールし、周辺リソースを作成するモジュールを作成します。

### 変数定義

`terraform/modules/albc/variables.tf`

```hcl
variable app_name {}
variable stage {}
variable cluster_name {}
variable ingress_cidr_blocks {
  // ALBへのアクセスを許可するCIDR
  type = list(string)
  default = ["0.0.0.0/0"]
}

data "aws_caller_identity" "self" { }
data "aws_region" "self" {}
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

locals {
  namespace = "kube-system"
  account_id = data.aws_caller_identity.self.account_id
  region = data.aws_region.self.name
  oidc_provider = replace(
    // AWS CLIで確認する場合: aws eks describe-cluster --name クラスタ名 --output text --query "cluster.identity.oidc.issuer"
    data.aws_eks_cluster.this.identity[0].oidc[0].issuer,
    "https://",
    ""
  )
  vpc_id = data.aws_eks_cluster.this.vpc_config[0].vpc_id
}
```

### リソース定義

aws-load-balancer-controllerがALBを作成するために必要なIAMロールを作成します。  
必要な権限は `https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json` にあるので、ダウンロードします。
※ 公式のIAMの作成手順はこちら: [ステップ 1: IAM を設定する - Kubernetes マニフェストを使用して AWS Load Balancer Controller アドオンをインストールする | AWS](https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/lbc-manifest.html#lbc-iam)

```bash
wget -P terraform/modules/albc "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json"
```

aws-load-balancer-controllerのサービスアカウントに割り当てるIAMロールを作成します。  
ポリシーには先ほどダウンロードした `iam_policy.json` を設定します。  
※ IAM vRoles for Service Accounts(IRSA) の説明はこちらの記事が非常にわかりやすい: [EKSの認証・認可の仕組み解説 | Zenn](https://zenn.dev/take4s5i/articles/aws-eks-authentication#iam-roles-for-service-accounts(irsa))


`terraform/modules/albc/main.tf`
```hcl
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
  // ファイルはこちらからDL: https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json
  policy = file("${path.module}/iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "aws_loadbalancer_controller" {
  role = aws_iam_role.aws_loadbalancer_controller.name
  policy_arn = aws_iam_policy.aws_loadbalancer_controller.arn
}
```

IAMロールを引き受けるサービスアカウントを定義します。

`terraform/modules/albc/main.tf`
```hcl
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
```

Helmで aws-load-balancer-controller をインストールします。

`terraform/modules/albc/main.tf`
```hcl
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
```

ALBに設定するセキュリティグループを定義します。

`terraform/modules/albc/main.tf`
```hcl
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
```

### outputの定義

kubernetesのマニフェストから参照できるようにセキュリティグループを出力に設定します。

`terraform/modules/albc/outputs.tf`

```hcl
output "alb_ingress_sg" {
  value = aws_security_group.ingress.id
}
```

## モジュールの利用

albcモジュールを `terraform/envs/dev/charts/main.tf` から呼び出します。

`terraform/envs/dev/charts/main.tf`
```hcl
module albc {
  source = "../../../modules/albc"
  app_name = local.app_name
  stage = local.stage
  cluster_name = local.cluster_name
}
```

albcモジュールの出力を出力します。


`terraform/envs/dev/charts/outputs.tf`
```hcl
output "alb_ingress_sg" {
  value = module.albc.alb_ingress_sg
}
```

# ■ metrics-server をインストール

Horizontal Pod Autoscaler を利用するために metrics-server をインストールします。

## モジュールの定義

`terraform/modules/hpa/main.tf`

```hcl
/**
 * metrics-serverチャートをインストールします。
 * - Kubernetes メトリクスサーバーのインストール | AWS: https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/metrics-server.html
 * - metrics-server | ArtifactHUB: https://artifacthub.io/packages/helm/metrics-server/metrics-server
 */

//helm_release - helm - terraform: https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.1"
  namespace  = "kube-system"
  create_namespace = true
}
```

## モジュールの利用

hpaモジュールを `terraform/envs/dev/charts/main.tf` から呼び出します。

`terraform/envs/dev/charts/main.tf`
```hcl
module hpa {
  source = "../../../modules/hpa"
}
```

# ■ secrets-store-csi-driver と secrets-store-csi-driver-provider-aws をインストール

Secrets Managerを利用するためのチャートをインストールします。


## モジュールの定義

secrets-store-csi-driver と secrets-store-csi-driver-provider-aws を Helm でインストールします。

`terraform/modules/secret-store-csi-driver/main.tf`
```hcl
/**
 * Secrets Store CSI Driver チャートのインストール
 *
 * - Kubernetes Secrets Store CSI Driver
 *   https://secrets-store-csi-driver.sigs.k8s.io/
 * - Amazon Elastic Kubernetes Service で AWS Secrets Manager シークレットを使用する
 *   https://docs.aws.amazon.com/ja_jp/secretsmanager/latest/userguide/integrating_csi_driver.html
 */
resource "helm_release" "csi_secrets_store" {
  //helm_release - helm - terraform: https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
  name       = "csi-secrets-store"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = "1.4.4"  # helm search repo secrets-store-csi-driver
  namespace  = "kube-system"
  create_namespace = true

  // Option Values - Secrets Store CSI Driver: https://secrets-store-csi-driver.sigs.k8s.io/getting-started/installation.html#optional-values
  set {
    // KubernetesのSecretオブジェクトへの同期を有効化
    name = "syncSecret.enabled"
    value = true
  }

  set {
    // シークレット情報変更時のローテーションを有効化
    name = "enableSecretRotation"
    value = true
  }
}

/**
 * ASCP (aws secrets store csi provider) チャートのインストール
 *
 * - secrets-store-csi-driver-provider-aws | GitHub
 *   https://github.com/aws/secrets-store-csi-driver-provider-aws
 * - Amazon Elastic Kubernetes Service で AWS Secrets Manager シークレットを使用する
 *   https://docs.aws.amazon.com/ja_jp/secretsmanager/latest/userguide/integrating_csi_driver.html
 */
resource "helm_release" "secrets_provider_aws" {
  //helm_release - helm - terraform: https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
  name       = "secrets-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  version    = "0.3.9"  # helm search repo secrets-store-csi-driver-provider-aws
  namespace  = "kube-system"
  create_namespace = true

  depends_on = [
    helm_release.csi_secrets_store
  ]
}
```

## モジュールの利用

secret-store-csi-driver モジュールを `terraform/envs/dev/charts/main.tf` から呼び出します。

`terraform/envs/dev/charts/main.tf`
```hcl
module secret_store_csi_driver {
  source = "../../../modules/secret-store-csi-driver"
}
```

# ■ デプロイ
```bash
# 初期化
terraform -chdir=terraform/envs/dev/charts init

# デプロイ内容確認
terraform -chdir=terraform/envs/dev/charts plan

# デプロイ
terraform -chdir=terraform/envs/dev/charts apply -auto-approve
```

## 確認

k9sで以下を確認します

- kube-systemネームスペースのdeploymentに `aws-load-balancer-controller` が存在する
- kube-systemネームスペースのdeploymentに `metrics-server` が存在する
- kube-systemネームスペースのdaemonsetに `csi-secrets-store-secrets-store-csi-driver` `secrets-provider-aws-secrets-store-csi-driver-provider-aws` が存在する