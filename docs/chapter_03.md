Chapter3 ネットワーク作成
---
[READMEに戻る](../README.md)

# ■ 作るもの

この章ではVPC、サブネットといったネットワークリソースを作成します。

## 構成図

<img width="900px" src="drawio/chapter_03/architecture.drawio.png">

## コンポーネント

<img width="800px" src="drawio/chapter_03/stack.drawio.png">

# ■ 変数定義

`terraform/components/network/variables.tf`

```tf
variable tfstate_bucket {
  type = string
  description = "tfvarsが保存されているバケット"
}

variable tfstate_region {
  type = string
  description = "tfvarsが保存されているバケットのリージョン"
}

variable tfstate_base_key {
  type = string
  description = "baseコンポーネントのtfstateファイルのパス"
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
    key    = var.tfstate_base_key
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

baseコンポーネントデプロイ時に入力値と指定する変数をtfvarsファイルにまとめます

`terraform/components/network/tfvars/dev.tfvars`

```ini
tfstate_bucket = "terraform-tutorial-eks-tfstate"
tfstate_region = "ap-northeast-1"
tfstate_base_key = "クラスタ名/base/terraform.tfstate"  # EDIT: クラスタ名を指定してください

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
# クラスタ名
CLUSTER_NAME=クラスタ名
# tfstateの保存先を定義した変数ファイル
COMMON_BACKEND_CONFIG=$PROJECT_DIR/tutorial/terraform/components/tfvars/dev.backend.tfvars
# コンポーネント名
COMPONENT_NAME=network
# コンポーネントディレクトリ
COMPONENT_DIR=$PROJECT_DIR/tutorial/terraform/components/$COMPONENT_NAME
# コンポーネントの入力変数ファイル
COMPONENT_TFVARS=$COMPONENT_DIR/tfvars/dev.tfvars

# 初期化
# -chdir terraformコマンドを実行するディレクトリ
# -reconfigure tfstateのバックエンド設定を再構成します
# -backend-config tfstateのバックエンド設定をファイルファイルまたは変数で指定します
terraform -chdir=$COMPONENT_DIR init \
  -reconfigure \
  -backend-config $COMMON_BACKEND_CONFIG \
  -backend-config "key=$CLUSTER_NAME/$COMPONENT_NAME/terraform.tfstate"

# デプロイ内容の確認
# -chdir terraformコマンドを実行するディレクトリ
# -var-file terraformの入力変数をファイルで指定します
terraform -chdir=$COMPONENT_DIR plan -var-file $COMPONENT_TFVARS

# デプロイ
# -chdir terraformコマンドを実行するディレクトリ
# -var-file terraformの入力変数をファイルで指定します
# -auto-approve terraformデプロイ時の確認プロンプトをスキップします
terraform -chdir=$COMPONENT_DIR apply -var-file $COMPONENT_TFVARS -auto-approve
```