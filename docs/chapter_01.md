Chapter1 Terraform入門
---
[READMEに戻る](../README.md)


# ■ 0. Terraform入門

- [Terraform公式ドキュメント](https://developer.hashicorp.com/terraform)

## Terraformとは


TerraformはCloudFormationやCDKのように、インフラを宣言的に記述できるツールです。  
Terraformの記述にはHCL(HashiCorp Configuration Language)と呼ばれる独自言語を利用します。
裏でCloudFormationが動いているわけではないので、デプロイしてもAWSマネジメントコンソールのCloudFormationの画面にスタックは作成されません。  
代わりに `terraform.tfstate` というファイルが生成され、このファイルに現在管理しているリソースなどの情報(状態)が保存されます。

## `terraform.tfstate` とは

`terraform.tfstate` にはterraform が現在管理しているリソースなどが保存されています。terraformはtfstateの内容とソースコードの差分を取って作成・変更・削除すべきリソースを抽出し、対象リソースのみをデプロイします。

`terraform.tfstate` は「現状デプロイされているリソースを管理する」という役割上、 環境に複数存在してはならず、同時に編集されてもいけません。しかしながら、デフォルトの設定ではこのファイルはローカルに生成され、重複と同時編集を許すことになってしまいます。

今回のチュートリアルでは、保存場所をs3に指定し、DynamoDBで同時編集に対するロックをかける方法を実装していきましょう。

## HCLとは

HCL (HashiCorp Configuration Language) はTerraformを記述するための独自言語です。  
ここでは、Terraformで利用する構文を少しだけ紹介します。

- 公式ドキュメントはこちら: [Terraform Language Documentation](https://developer.hashicorp.com/terraform/language)

### Providers

- [Providers | Terraform](https://developer.hashicorp.com/terraform/language/providers)

TerraformはawsだけでなくGCPやAzureといったマルチプラットフォームで利用できるツールですが、それぞれのシステムとやりとりをするために、「プロバイダ」というプラグインを利用利用します。  
awsならawsプロバイダ、GCPならgoogleプロバイダといった具合に、バックエンドとなるサービスごとにプロバイダが存在し、プロバイダをインストールしていない状態では、いかなるインフラも定義することはできません。  
※ helmやkubernetesといったプロバイダも存在します。


`terraform.required_providers` 必要なプロバイダを定義し、`provider` ブロックでインストールしたプロバイダの設定を行います。

- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

```hcl
terraform {
  required_providers { // 必要なプロバイダを定義
    aws = { // awsプロバイダのインストール
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" { // awsプロバイダの設定
  region = "ap-northeast-1"
}
```

### Resources

- [Resources | Terraform](https://developer.hashicorp.com/terraform/language/resources)  


`resource` ブロックではVPCやサブネット、EC2といったインフラオブジェクトを定義します。`resource` ブロックで定義できるインフラはプロバイダごとに定義されており、awsであれば、[aws provider ドキュメント](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) から調べることができます。


例えばAWSインスタンスは下記のように定義します。
`aws_instance` はリソースタイプで、 `some` は任意の名前となります。 (リソースタイプと名前の組み合わせはモジュール内でユニークでなければなりません。)

- [aws_instance | aws provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)


```hcl
resource "aws_instance" "some" {
  ami           = "ami-a1b2c3d4"
  instance_type = "t2.micro"
}
```

#### Meta-Arguments

リソースには、リソースごとの設定のほかに、どのリソースも共通して利用可能な [Meta-Arguments](https://developer.hashicorp.com/terraform/language/meta-arguments/depends_on) という設定値があります。  
Meta-Argumentsには、リソースの依存関係を明確にするための `depends_on` 、 リソースの数を指定する `count` 、 変更無視や削除禁止などを定義する `lifecycle` などがあります。

##### lifecycle

`lifecycle` では作成したリソースに削除保護をかけたり、変更を適用しないパラメータを指定したりすることができます。

- [The lifecycle Meta-Argument | Terraform](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle)

初回デプロイ後に変更・削除されないALBを作る例

```hcl
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_alb_sg.id]
  subnets            = ["xxxxxxxxxx", "xxxxxxxxxx]
  ip_address_type    = "ipv4"
  idle_timeout       = 60

  lifecycle {
    # すべてのパラメータにおいて変更を適用しない
    # https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#ignore_changes
    ignore_changes = all

    # 削除を禁止することで、強制的なリソースの再作成が起こらないようにする
    # https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#prevent_destroy
    prevent_destroy = true
  }
}

```

##### for_each

設定値が近しいリソースを複数作成するなど、ループ処理が必要な場合は `for_each` を利用します。


- [The for_each Meta-Argument | Terraform](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle)

リストに定義されている名前で複数のバケットを作成する例

```hcl
locals {
  buckets = ["assets", "media"]
}

resource "aws_s3_bucket" "example" {
  for_each = toset(local.backets)  # 辞書もしくはセット型にする必要がある
  bucket   = "${each.key}_bucket"  # キーであれば each.key バリューであれば each.value で値を参照
}
```

指定されたポートへの入力を許可するセキュリティグループの例

```hcl
locals {
  ingress_ports = [22, 80, 443]
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  vpc_id      = "vpc-xxxxxxxxx"

  dynamic "ingress" {
    for_each = toset(var.ingress_ports)

    content {
      description = "Allow cluster additional SecurityGroup access"
      from_port   = each.key
      to_port     = each.key
      protocol    = "all"
      cidr_blocks = ["10.0.0.0/8", "192.168.0.0/16"]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
```


### DataSource

- [Data Sources](https://developer.hashicorp.com/terraform/language/data-sources)  

`data` ブロックはTerraformの外部で定義されたリソースを参照するためのブロックです。 `data` ブロックで定義されたデータリソースは読み取り専用で、たとえ変更したとしても既存のリソースが更新・削除されることはありません。

例えば `data` ブロックで取得したamiの参照を利用して `aws_instance` リソースを定義するには、下記のように実装します。

- [aws_ami | aws provider]()https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

```hcl
data "aws_ami" "this" {  // 既存のamiの参照を取得
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

resource "aws_instance" "some" {  // amiの参照を指定してEC2インスタンスを定義
  ami           = data.aws_ami.this.id
  instance_type = "t2.micro"
}
```

### Valiable・Output

- [Variable and Outputs](https://developer.hashicorp.com/terraform/language/values)  

`variable` ブロックで入力変数、 `output` ブロックで出力値 、 `locals` ブロックでローカル変数を定義することができます。


#### 1. variable

- [Input Variables | Terraform](https://developer.hashicorp.com/terraform/language/values/variables)

`variable` ブロックはモジュールの入力変数を定義します。(いわゆる関数における引数です)   
`variable` ブロックで定義した変数は、terraformをデプロイするときに入力を求められます。  
`variable` ブロックには、型を指定する `type` 、 デフォルト値を指定する `default` などいくつかの引数があります。

※ `type` には [Types and Values | Terraform](https://developer.hashicorp.com/terraform/language/expressions/types) の型が指定できます。


```hcl

variable "image_id" {
  type = string
  default = "ami-xxxxxx"
}

resource "aws_instance" "some" {
  ami           = var.image_id  // variableを参照
  instance_type = "t2.micro"
}
```


#### 2. output

- [Output Values | Terraform](https://developer.hashicorp.com/terraform/language/values/outputs)

`output` ブロックはモジュールの出力値を定義します。(いわゆる関数における戻り値です。)  
`output` ブロックで定義した出力値は、モジュールの外から参照できます。別のモジュールに値を引き渡したいときに利用します。

```hcl

resource "aws_instance" "some" {
  ami           = "ami-xxxxx"
  instance_type = "t2.micro"
}

output instance_arn {
  value = aws_instance.some.arn
}
```

#### 3. locals

- [Local Values | Terraform](https://developer.hashicorp.com/terraform/language/values/locals)

ローカル変数には、モジュール内で何度も繰り返し利用する値などを定義します。(いわゆる関数におけるローカル変数です。)  


```hcl

locals {
  instance_type = "t2.micro"
}

resource "aws_instance" "some" {
  ami           = "ami-xxxxx"
  instance_type = local.instance_type
}

resource "aws_instance" "other" {
  ami           = "ami-xxxxx"
  instance_type = local.instance_type
}

```

### Modules

- [Modules](https://developer.hashicorp.com/terraform/language/modules)  


モジュールはいくつかのリソースを再利用可能な粒度でまとめるための機能です。  
モジュールはディレクトリ単位で作られ、あるディレクトリに格納されている `tf` ファイルの集まりがモジュールとなります。

例えば、下記のようなディレクトリ構成の場合、 `terraform/alb` 配下の `main.tf` `variables.tf` `outputs.tf` が一つのモジュールとなります。


```
- terraform/
  - main.tf
  - alb/
    - main.tf
    - variables.tf
    - outputs.tf
```

`terraform/main.tf` から `alb` モジュールを利用するには、下記のように実装します。

```hcl
module "some_alb" {
  source = "./alb"
  // albモジュールが variable を持つ場合は引数として与えます
  some_variable = "hogehoge"
  other_variable = 3
}

// albモジュールが output を持つ場合は参照することができます
retource "aws_xxxxxxxxxxx" "xxxxxxxxx" {
  alb_arn = module.some_alb.arn
}
```


### Functions

- [Functions](https://developer.hashicorp.com/terraform/language/functions)  

Terraformには様々な組み込み関数が実装されており、文字列や数値などのちょっとした編集が可能です。  
`terraform console` を起動していくつかの関数を実行してみましょう

```bash
terraform console
```

```
> max(5, 12, 9)
12

> lower("Hello")
"hello"

> contains(["a", "b", "c"], "a")
true

> jsonencode({hello = "world", foo = 3})
"{\"foo\":3,\"hello\":\"world\"}"
```


## 利用する主なコマンド

- [Terraform CLI Documentation](https://developer.hashicorp.com/terraform/cli)



```bash
# プロバイダプラグインのインストールなど、terraformコマンドを利用するための初期化処理を行うコマンド
terraform init

# 組み込み関数などの動作確認を行えるプロンプトを立ち上げるコマンド
# 例)
# > replace("hoge-fuga", "-", "_")
# "hoge_fuga"
terraform console


# 構文が正しいかのバリデーションを行うコマンド
terraform validate

# tfファイルのフォーマットを行うコマンド
#   -recursive: 再帰的にフォーマットできる
terraform fmt

# 現在のデプロイ状況と比較し、どんなリソースが作成(削除)されるかを確認するコマンド
terraform plan

# 定義したリソースをデプロイするコマンド
#   -auto-approve: インタラクティブな確認をスキップできる
#   -target=path.to.resource: 指定したリソースのみデプロイできる
terraform apply

# 定義したリソースを削除するコマンド
#   -auto-approve: インタラクティブな確認をスキップできる
#   -target=path.to.resource: 指定したリソースのみ削除できる
terraform destroy

# ロックを強制解除する: https://developer.hashicorp.com/terraform/cli/commands/force-unlock
#   -force: インタラクティブな確認をスキップできる
terraform force-unlock <LOCK_ID>
```

## そのほか参考資料

- [それ、どこに出しても恥ずかしくない Terraformコードになってるか？ | AWS](https://esa-storage-tokyo.s3-ap-northeast-1.amazonaws.com/uploads/production/attachments/5809/2023/07/07/19598/c89126e6-8d48-4e34-a654-6fd29b63756e.pdf)

# ■ 1. ディレクトリ作成

プロジェクトのディレクトリを作成しましょう。 terraformリソースは `terraform/` ディレクトリ配下に定義します。

## ディレクトリ構成

- `terraform/`
  - `envs/`
    dev, stg, prd など、環境毎にディレクトリを切る
  - `modules/`
    サービス毎・ライフサイクル毎にある程度リソースをグループ化したモジュールを配置

```bash
STAGE="ステージ名"

# プロジェクトディレクトリ作成
mkdir -p "$CONTAINER_PROJECT_ROOT/terraform/envs/${STAGE}" "$CONTAINER_PROJECT_ROOT/terraform/modules"
```

## .gitignore配置

```bash
cat <<EOF > terraform/.gitignore
# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files, which are likely to contain sensitive data, such as
# password, private keys, and other secrets. These should not be part of version 
# control as they are data points which are potentially sensitive and subject 
# to change depending on the environment.
*.tfvars
*.tfvars.json

# Ignore override files as they are usually used to override resources locally and so
# are not checked in
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Include override files you do wish to add to version control using negated pattern
# !example_override.tf

# Include tfplan files to ignore the plan output of command: terraform plan -out=tfplan
# example: *tfplan*

# Ignore CLI configuration files
.terraformrc
terraform.rc

**/*.auto.tfvars
EOF
```

# ■ 2. プロバイダの設定

今回作成するリソースはすべてAWSのリソースであるため、 `hashicorp/aws` プロバイダプラグインをインストールして、それを利用できるように設定していきます。  
terraformではリソースを `terraform.tfstate` というファイルで管理しますが、デフォルトだとこのファイルはローカルに生成されてしまうため、s3バケットに保存するように設定します。  
また、terraformでは環境に対して同時に操作を行うと環境が壊れてしまうため、 `terraform.tfstate` にロック機構を設けることで環境に同時に操作が行われることを防止します。このロックはDynamoDBで管理します。

- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

```bash
touch ${CONTAINER_PROJECT_ROOT}/terraform/envs/${STAGE}/main.tf
```

※ `EDIT: ...` コメントの項目を各自編集してください

`terraform/envs/${STAGE}/main.tf`

```hcl
terraform {
  required_providers {
    // AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  // terraformのバージョン指定
  required_version = ">= 1.2.0"

  // tfstateファイルをs3で管理する: https://developer.hashicorp.com/terraform/language/settings/backends/s3
  backend "s3" {
    // tfstate保存先のs3バケットとキー
    bucket  = "xxxxxxxxxxxx"  // EDIT: chapter0で作成したtfstate保存用バケットを指定
    region  = "ap-northeast-1"
    key     = "path/to/terraform.tfstate"  // EDIT: tfstateを保存するパスを指定
    encrypt = true
    // tfstateファイルのロック情報をDynamoDBで管理する: https://developer.hashicorp.com/terraform/language/settings/backends/s3#dynamodb-state-locking
    dynamodb_table = "xxxxxxxxxxxx"  // EDIT: chapter0で作成したtfstateロック用のDynamoDBテーブル名を指定
  }
}

provider "aws" {
  region = "ap-northeast-1"

  // すべてのリソースにデフォルトで設定するタグ
  default_tags {
    tags = {
      PROJECT_NAME = "TERRAFORM_TUTORIAL_D"
    }
  }
}

// Data Source: aws_caller_identity: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity
// Terraformが認可されているアカウントの情報を取得するデータソース
data "aws_caller_identity" "self" {}

// Data Source: aws_region: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region
// 現在のリージョンを取得するデータソース
data "aws_region" "current" {}
```


# ■ 3. terraformデプロイ

現時点ではリソースは作成されませんが、一度デプロイと削除を試してみましょう。

```bash
cd ${CONTAINER_PROJECT_ROOT}/terraform/envs/${STAGE}

# 初期化
terraform init

# デプロイ内容確認
terraform plan

# デプロイ
terraform apply -auto-approve
```

tfstateが指定したs3バケットの指定されたキーに作成されているかを確認してみましょう。

<img src="img/01/tfstate_s3_bucket.png" width="500px">


DynamoDBにtfstateのロックレコードが生成されていることを確認してみましょう。

<img src="img/01/tfstate_lock_dynamodb.png" width="500px">


```bash
# 削除
terraform destroy -auto-approve
```


# ■ 4. baseモジュールの作成

sns topic を作成する `base` モジュールを作成してみましょう。


## 1. ファイル作成

`base` モジュールを作成します。

```bash
STAGE="ステージ名"
mkdir -p ${CONTAINER_PROJECT_ROOT}/terraform/modules/base
touch ${CONTAINER_PROJECT_ROOT}/terraform/modules/base/{main.tf,variables.tf,outputs.tf}
```

## 2. リソース定義


`terraform/modules/base/variables.tf`

```hcl
variable "app_name" {}
variable "stage" {}
```

`terraform/modules/base/outputs.tf`

```hcl
output "sns_topic_arn" {
  value = aws_sns_topic.this.arn
}
```

`terraform/modules/base/main.tf`

```hcl
resource "aws_sns_topic" "this" {
  name = "${var.app_name}-${var.stage}-topic"
  lifecycle {
    ignore_changes = all
  }
}
```

## 3. モジュールをエントリーポイントから参照

モジュールに定義したリソースはエントリーポイント ( `terraform/envs/${STAGE}/main.tf` )から、関数のように呼び出すことでデプロイできます。

※ `EDIT: ...` コメントの項目を各自編集してください


```hcl
// ... 略 ...

// ローカル変数を定義
locals {  // < 追加 >
  aws_region      = data.aws_region.current.name
  account_id      = data.aws_caller_identity.self.account_id
  app_name        = replace(lower("terraformtutorial"), "-", "")
  stage           = "ステージ名"  // EDIT: STAGEに指定した名前
  vpc_cidr_block  = "xxx.xxx.xxx.xxx/16"  // EDIT: VPCのCIDRブロック
  repository_name = "xxxxxxxxxxxx"  // EDIT: CodeCommitに作成したリポジトリ名
}

module "base" {  // < 追加 >
  source = "../../modules/base"
  app_name    = local.app_name
  stage       = local.stage
}
```


## 4. デプロイ

```bash
cd ${CONTAINER_PROJECT_ROOT}/terraform/envs/${STAGE}

# 初期化
terraform init

# デプロイ内容確認
terraform plan

# デプロイ
terraform apply -auto-approve
```