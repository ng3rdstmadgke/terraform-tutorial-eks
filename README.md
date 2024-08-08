# Terraformのインストール


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