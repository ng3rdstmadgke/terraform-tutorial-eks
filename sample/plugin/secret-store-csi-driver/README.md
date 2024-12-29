# Secrets Store CSI Driver

- [Kubernetes Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/)
- [Amazon Elastic Kubernetes Service で AWS Secrets Manager シークレットを使用する](https://docs.aws.amazon.com/ja_jp/secretsmanager/latest/userguide/integrating_csi_driver.html)


```bash
# リポジトリ追加
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts

# リポジトリのアップデート
helm repo update

# インストールするチャートのバージョンチェック
CHART_VERSION=$(helm show chart secrets-store-csi-driver/secrets-store-csi-driver | yq -r ".version")
echo $CHART_VERSION

# インストール
helm upgrade --install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --version "1.4.7" \
  --namespace kube-system \
  --create-namespace \
  --set "syncSecret.enabled=true" \
  --set "enableSecretRotation=true"
```

# ASCP (aws secrets store csi provider)

- [secrets-store-csi-driver-provider-aws | GitHub](https://github.com/aws/secrets-store-csi-driver-provider-aws)
- [Amazon Elastic Kubernetes Service で AWS Secrets Manager シークレットを使用する](https://docs.aws.amazon.com/ja_jp/secretsmanager/latest/userguide/integrating_csi_driver.html)


```bash
# リポジトリ追加
helm repo add aws-secrets-manager https://aws.github.io/secrets-store-csi-driver-provider-aws

# リポジトリのアップデート
helm repo update

# インストールするチャートのバージョンチェック
CHART_VERSION=$(helm show chart aws-secrets-manager/secrets-store-csi-driver-provider-aws | yq -r ".version")
echo $CHART_VERSION

# インストール
helm upgrade --install secrets-provider-aws aws-secrets-manager/secrets-store-csi-driver-provider-aws \
  --version "0.3.10" \
  --namespace kube-system \
  --create-namespace
```