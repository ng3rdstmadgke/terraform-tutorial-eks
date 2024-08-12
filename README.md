# ■ インストール
## Terraformのインストール

https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

# HashiCorp GPG キーをインストール
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# GPGキーのフィンガープリントを確認
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

# HashiCorp リポジトリをシステムに追加
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

# HashiCorp リポジトリのパッケージ情報を更新
sudo apt update

# terraformをインストール
sudo apt-get install terraform

# 確認
terraform version
```

completionの設定

```bash
terraform -install-autocomplete
source ~/.bashrc
```

## awscliのインストール

https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

completion の設定

```bash
echo "complete -C '/usr/local/bin/aws_completer' aws" >> ~/.bashrc
source ~/.bashrc
```

## kubectlのインストール

```bash
curl -LO https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

completionの設定

```bash
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc
```

## k9sのインストール

```bash
sudo snap install k9s --devmode
```


# ■ デプロイ

## EKS クラスタ

```bash
terraform -chdir=sample/terraform/envs/dev/cluster init
terraform -chdir=sample/terraform/envs/dev/cluster plan
terraform -chdir=sample/terraform/envs/dev/cluster apply -auto-approve
```

## チャート

```bash
terraform -chdir=sample/terraform/envs/dev/charts init
terraform -chdir=sample/terraform/envs/dev/charts plan
terraform -chdir=sample/terraform/envs/dev/charts apply -auto-approve
```


```bash
CLUSTER_NAME=tutorial-mido-dev
aws eks update-kubeconfig --name $CLUSTER_NAME
```