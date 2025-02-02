Chapter1 Terraform入門
---
[READMEに戻る](../README.md)


# ■ Terraform入門

- [Terraform公式ドキュメント](https://developer.hashicorp.com/terraform)

## Terraformとは


TerraformはCloudFormationやCDKのように、インフラを宣言的に記述できるツールです。  
Terraformの記述にはHCL(HashiCorp Configuration Language)と呼ばれる独自言語を利用します。
裏でCloudFormationが動いているわけではないので、デプロイしてもAWSマネジメントコンソールのCloudFormationの画面にスタックは作成されません。  
代わりに `terraform.tfstate` というファイルが生成され、このファイルに現在管理しているリソースなどの情報(状態)が保存されます。

## `terraform.tfstate` とは

`terraform.tfstate` にはterraform が現在管理しているリソースなどが保存されています。terraformはtfstateの内容とソースコードの差分を取って作成・変更・削除すべきリソースを抽出し、対象リソースのみをデプロイします。

`terraform.tfstate` は「現状デプロイされているリソースを管理する」という役割上、 環境に複数存在してはならず、同時に編集されてもいけません。しかしながら、デフォルトの設定ではこのファイルはローカルに生成され、重複と同時編集を許すことになってしまいます。

今回のチュートリアルでは、保存場所をs3に指定し、ロックファイルを利用してロックをかける方法を実装していきましょう。

## HCLとは

HCL (HashiCorp Configuration Language) はTerraformを記述するための独自言語です。  
ここでは、Terraformで利用する構文を少しだけ紹介します。

- 公式ドキュメントはこちら: [Terraform Language Documentation](https://developer.hashicorp.com/terraform/language)

### Providers

- [Providers | Terraform](https://developer.hashicorp.com/terraform/language/providers)

TerraformはawsだけでなくGCPやAzureといったマルチプラットフォームで利用できるツールですが、それぞれのシステムとやりとりをするために、「プロバイダ」というプラグインを利用します。  
awsならawsプロバイダ、GCPならgoogleプロバイダといった具合に、バックエンドとなるサービスごとにプロバイダが存在し、プロバイダをインストールしていない状態では、いかなるインフラも定義することはできません。  
※ helmやkubernetesといったプロバイダも存在します。

プロバイダの検索は [Browse Providers | Terraform Registry](https://registry.terraform.io/browse/providers) から行います。


`terraform.required_providers` 必要なプロバイダを定義し、`provider` ブロックでインストールしたプロバイダの設定を行います。

- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

```tf
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


```tf
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

```tf
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

```tf
locals {
  buckets = ["assets", "media"]
}

resource "aws_s3_bucket" "example" {
  for_each = toset(local.backets)  # 辞書もしくはセット型にする必要がある
  bucket   = "${each.key}_bucket"  # キーであれば each.key バリューであれば each.value で値を参照
}
```

指定されたポートへの入力を許可するセキュリティグループの例

```tf
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

```tf
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


```tf

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

```tf

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


```tf

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

```tf
module "some_alb" {
  source = "./alb"
  // albモジュールが variable を持つ場合は引数として与えます
  some_variable = "hogehoge"
  other_variable = 3
}

// albモジュールが output を持つ場合は参照することができます
retource "aws_xxxxxxxxxxx" "xxxxxxxxx" {
  alb_arn = module.some_alb.some_output
}
```

また、サードパーティー製のモジュールをプログラミング言語のライブラリのように利用することも可能です。

※ 公開されているモジュールは [Modules Registry | Terraform](https://registry.terraform.io/browse/modules) から検索します。

```tf
module "iam_account" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-account"

  account_alias = "awesome-company"

  minimum_password_length = 37
  require_numbers         = false
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
# [options]
#   -reconfigure  : バックエンドの設定を再構成し、Terraform の環境を再初期化する
#   -migrate-state: tfstateファイルを新しいバックエンドに移行する
terraform init [options]

# 組み込み関数などの動作確認を行えるプロンプトを立ち上げるコマンド
# 例)
# > replace("hoge-fuga", "-", "_")
# "hoge_fuga"
terraform console


# 構文が正しいかのバリデーションを行うコマンド
terraform validate

# tfファイルのフォーマットを行うコマンド
# [options]
#   -recursive: 再帰的にフォーマットできる
terraform fmt [options]

# 現在のデプロイ状況と比較し、どんなリソースが作成(削除)されるかを確認するコマンド
terraform plan

# 定義したリソースをデプロイするコマンド
# [options]
#   -auto-approve: インタラクティブな確認をスキップできる
#   -target=path.to.resource: 指定したリソースのみデプロイできる
terraform apply [options]

# outputブロックで定義した変数を出力するコマンド
# [options]
#   -raw: クォーテーションを省いたスクリプトで利用しやすい形式で出力
terraform output [options] [出力変数名]

# 定義したリソースを削除するコマンド
# [options]
#   -auto-approve: インタラクティブな確認をスキップできる
#   -target=path.to.resource: 指定したリソースのみ削除できる
terraform destroy [options]

# ロックを強制解除する: https://developer.hashicorp.com/terraform/cli/commands/force-unlock
# [options]
#   -force: インタラクティブな確認をスキップできる
terraform force-unlock [options] <LOCK_ID>
```

## そのほか参考資料

- [それ、どこに出しても恥ずかしくない Terraformコードになってるか？ | AWS](https://esa-storage-tokyo.s3-ap-northeast-1.amazonaws.com/uploads/production/attachments/5809/2023/07/07/19598/c89126e6-8d48-4e34-a654-6fd29b63756e.pdf)

# ■ 環境構築

Terraform, aws-cli, kubectl, k9s, helmなどのパッケージはdevcontainerに含まれています。  
インストール方法は [.devcontainer/Dockerfile](../.devcontainer/Dockerfile)を参照ください。

## AWSのクレデンシャル設定

AWSのリソースを作成するにあたって、リソースを作成するための権限が必要です。  
`arn:aws:iam::aws:policy/AdministratorAccess` ロールを持つユーザーのアクセスキーIDとシークレットアクセスキーをdefaultプロファイルに設定してください。

`~/.aws/config`

```ini
[default]
region=ap-northeast-1
output=json
```

`~/.aws/credentials`


```ini
[default]
aws_access_key_id = xxxxxxxxxxxxxxxxxxxx
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

# ■ 最初のTerraformコード

これまでの内容のおさらいとして簡単なTerraformコードを実装して、リソースを作成してみましょう。

## テスト用のプロジェクト作成

テスト用のTerraformを実装するためのプロジェクトを作成します。

```bash
# ディレクトリ作成
mkdir -p tmp/sample_resource
cd tmp/sample_resource

# Terraformのファイル作成
touch main.tf
```

## tfstateとプロバイダの設定

- `terraform`
  - `required_version`  
  インストールしてあるTerraformのバージョンを指定します。 ( `terraform --version` )
  - `required_providers`  
  利用するプロバイダを指定します。今回は [AWSプロバイダ](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) を利用します。
- `provider`  
awsプロバイダの設定を記述します。


`tmp/sample_resource/main.tf`


```tf
terraform {
  required_version = "~> 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
  default_tags {  // すべてのリソースに付与するタグ
    tags = {
      PROJECT = "TERRAFORM_TUTORIAL_EKS_TEST",
    }
  }
}
```


## リソースの定義

s3バケットを作成するサンプルを作成します。  
このTerraformでは、`{ユーザー入力}-{ランダム文字列}` をバケット名とするバケットを作成し、作成したバケットのARNを出力として返します。


`tmp/sample_resource/main.tf`


```tf
// バケット名のプレフィックスを入力として受け取る
variable bucket_prefix {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket

  type = string
  description = "s3 bucket name prefix"
  validation {
    condition = length(var.bucket_prefix) > 2 && length(var.bucket_prefix) < 56 && can(regex("^[a-z\\d][a-z\\d.-]+[a-z\\d]$", var.bucket_prefix))
    error_message = "invalid bucket name."
  }
}

// バケットARNを出力として返す
output bucket_arn {
  value = aws_s3_bucket.example.arn
}

// ランダム文字列の生成
resource "random_string" "bucket_suffix" {
  // https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string

  length  = 8
  lower   = true  # 小文字を文字列に含める
  numeric = true  # 数値を文字列に含める
  upper   = false # 大文字を文字列に含めない
  special = false # 記号を文字列に含めない
}


// バケットの定義
resource "aws_s3_bucket" "example" {
  bucket = "${var.bucket_prefix}-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
```

## デプロイ

作成したリソースをデプロイしてみましょう

```bash
# プロジェクトの初期化 (プロバイダのインストールなどを行います)
$ terraform init

# 作成されるリソースの確認
$ terraform plan

var.bucket_prefix
  s3 bucket name prefix

  Enter a value: <バケット名のプレフィックス>

# リソースの作成
$ terraform apply

var.bucket_prefix
  s3 bucket name prefix

  Enter a value: <バケット名のプレフィックス>

...

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: <yesを入力>
```

デプロイを行うと、terraformによって管理されているリソースの状態を保存する `terraform.tfstate` というファイルが生成されます。  
`terraform apply` 実行時は、`terraform.tfstate` とソースコードの差分が発生している箇所のみをデプロイします。  

`terraform.tfstate` で管理されているリソースを少し確認してみましょう

```bash
# tfstateで管理されているリソースを一覧表示します。
$ terraform state list
aws_s3_bucket.example
random_string.bucket_suffix

# tfstateで管理されているリソースの詳細を表示します。
$ terraform state show aws_s3_bucket.example
```

実際にs3バケットが作成されていることを確認します

```bash
aws s3 ls | grep "バケット名のプレフィックス"
```

## 削除

```bash
$ terraform destroy

var.bucket_prefix
  s3 bucket name prefix

  Enter a value: <バケット名のプレフィックス>

...

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: <yesを入力>
```