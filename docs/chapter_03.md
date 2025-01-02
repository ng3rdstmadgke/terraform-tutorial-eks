Chapter3 ネットワーク作成
---
[READMEに戻る](../README.md)

# ■ 作るもの

この章ではVPC、サブネットといったネットワークリソースを作成します。

<img width="900px" src="drawio/chapter_03/architecture.drawio.png">

# ■ 変数定義


`terraform/envs/dev/network/variables.tf`

```tf
locals {
  cluster_name = data.terraform_remote_state.base.outputs.cluster_name
  vpc_cidr = "10.XX.0.0/16"  // EDIT: 重複しないCIDRを指定してください
  private_subnets = [  // EDIT: VPCのCDIRに応じてプライベートサブネットのCIDRを3つ指定してください
    "10.XX.1.0/24",
    "10.XX.2.0/24",
    "10.XX.3.0/24",
  ]
  public_subnets = [  // EDIT: VPCのCDIRに応じてパブリックサブネットのCIDRを3つ指定してください
    "10.XX.101.0/24",
    "10.XX.102.0/24",
    "10.XX.103.0/24",
  ]
}

// baseコンポーネントのステートを参照
data "terraform_remote_state" "base" {
  backend = "s3"

  config = {
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "XXXXX/dev/base/terraform.tfstate"  // EDIT: baseコンポーネントのkeyに設定した値を設定してください
    region = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "terraform-tutorial-eks-tfstate-lock"
  }
}
```

# ■ VPCの作成


## tfstateとプロバイダの設定

`terraform/envs/dev/network/main.tf`


```tf
terraform {
  required_version = "~> 1.10"

  backend "s3" {
    bucket = "terraform-tutorial-eks-tfstate"
    key    = "XXXXX/dev/network/terraform.tfstate"  // EDIT: XXXXX に重複しない任意の値を指定してください
    region = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "terraform-tutorial-eks-tfstate-lock"
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

`terraform/envs/dev/network/main.tf`


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

```

# ■ 出力値の定義

他のコンポーネントから参照するための値を出力値として定義します。

`terraform/envs/dev/network/outputs.tf`

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

# ■ terraformデプロイ

terraformを実行してVPCを作成してみましょう

```bash
cd $PROJECT_DIR/tutorial/terraform/envs/dev/network

# 初期化
terraform init

# デプロイ内容確認
terraform plan

# デプロイ
terraform apply -auto-approve
```