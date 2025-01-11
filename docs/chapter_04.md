Chapter4 ネットワーク作成
---
[READMEに戻る](../README.md)

# ■ 作るもの

この章ではVPC、サブネットといったネットワークリソースを作成します。

## 構成図

<img width="900px" src="drawio/chapter_04/architecture.drawio.png">

## コンポーネント

<img width="800px" src="drawio/chapter_04/stack.drawio.png">

# ■ 変数定義

`terraform/components/network/variables.tf`

```tf
variable project_name {
  type = string
  description = "プロジェクト名"
}

variable stage {
  type = string
  description = "ステージ名"
}

variable tfstate_bucket {
  type = string
  description = "tfvarsが保存されているバケット"
}

variable tfstate_region {
  type = string
  description = "tfvarsが保存されているバケットのリージョン"
}

variable "vpc_cidr" {
  type = string
  description = "VPCのCIDR"
}

variable "private_subnets" {
  type = list(string)
  description = "プライベートサブネットのCIDR"
}

variable "public_subnets" {
  type = list(string)
  description = "パブリックサブネットのCIDR"
}

locals {
  cluster_name = data.terraform_remote_state.base.outputs.cluster_name
}

data terraform_remote_state "base" {
  backend = "s3"

  config = {
    region = var.tfstate_region
    bucket = var.tfstate_bucket
    key    = "${var.project_name}/${var.stage}/base/terraform.tfstate"
  }
}
```

# ■ VPCの作成


## tfstateとプロバイダの設定

`terraform/components/network/main.tf`


```tf
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
```

## VPCリソースの定義

VPCの構築には [terraform-aws-modules/vpc/aws](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) モジュールを利用します。  

`terraform/components/network/main.tf`


```tf
/**
 * VPC作成
 *
 * terraform-aws-modules/vpc/aws | Terraform
 * https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
 */
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.17.0"

  name = "${local.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

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
```

# ■ 出力値の定義

他のコンポーネントから参照するための値を出力値として定義します。

`terraform/components/network/outputs.tf`

```tf
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}
```

# ■ networkコンポーネントの入力変数ファイルの作成

※ `EDIT: ...` コメントの項目を各自編集してください

networkコンポーネントデプロイ時に入力値と指定する変数をtfvarsファイルにまとめます

`terraform/components/network/tfvars/dev.tfvars`

```ini
vpc_cidr = "10.xx.0.0/16"  # EDIT: 重複しないネットワークを指定してください
private_subnets = [  # EDIT: 重複しないネットワークを指定してください
  "10.xx.1.0/24",
  "10.xx.2.0/24",
  "10.xx.3.0/24",
]
public_subnets = [  # EDIT: 重複しないネットワークを指定してください
  "10.xx.101.0/24",
  "10.xx.102.0/24",
  "10.xx.103.0/24",
]
```

# ■ terraformデプロイ

terraformを実行してVPCを作成してみましょう

```bash
# プロジェクト名
PROJECT_NAME=プロジェクト名
# ステージ名
STAGE=dev
# コンポーネント
COMPONENT=network

# terraform plan: 作成されるリソース、現在との差分の確認
# 実行後に .tfplan/network/plan.tfgraph ファイルが生成されるのでVSCodeで開いてみましょう。作成されるリソースの詳細を確認することができます。
make tf-plan PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=$COMPONENT

# terraform apply: デプロイ
make tf-apply PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=$COMPONENT

# terraform output: 出力値の確認
make tf-output PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=$COMPONENT
```