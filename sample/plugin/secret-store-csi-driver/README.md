# Secrets Store CSI Driver のインストール

- [Kubernetes Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/)
- [Amazon Elastic Kubernetes Service で AWS Secrets Manager シークレットを使用する](https://docs.aws.amazon.com/ja_jp/secretsmanager/latest/userguide/integrating_csi_driver.html)


リポジトリ追加

```bash
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
```

リポジトリのアップデート


```bash
helm repo update
```

チャートのバージョンチェック

```bash
helm show chart secrets-store-csi-driver/secrets-store-csi-driver  | yq ".version"
```


インストール


```bash
helm upgrade --install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --version "1.4.7" \
  --namespace kube-system \
  --create-namespace \
  --set "syncSecret.enabled=true" \
  --set "enableSecretRotation=true"
```

# ASCP (aws secrets store csi provider) のインストール


- [secrets-store-csi-driver-provider-aws | GitHub](https://github.com/aws/secrets-store-csi-driver-provider-aws)
- [Amazon Elastic Kubernetes Service で AWS Secrets Manager シークレットを使用する](https://docs.aws.amazon.com/ja_jp/secretsmanager/latest/userguide/integrating_csi_driver.html)


リポジトリ追加

```bash
helm repo add aws-secrets-manager https://aws.github.io/secrets-store-csi-driver-provider-aws
```

リポジトリのアップデート


```bash
helm repo update
```

チャートのバージョンチェック

```bash
helm show chart aws-secrets-manager/secrets-store-csi-driver-provider-aws | yq ".version"
```


インストール


```bash
helm upgrade --install secrets-provider-aws aws-secrets-manager/secrets-store-csi-driver-provider-aws \
  --version "0.3.10" \
  --namespace kube-system \
  --create-namespace
```