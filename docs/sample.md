サンプルのデプロイ手順
---

# ■ terraform, aws-cli, kubectl, helm のインストール手順

devcontainerに含まれています。  
インストール手順は `.devcontainer/Dockerfile` を参照

# ■ デプロイ

```bash
# プロジェクト名
PROJECT_NAME=tte-mido
# ステージ名
STAGE=dev
```

## ベーススタック


```bash
make tf-plan PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=base
make tf-apply PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=base
```

## ネットワークスタック

```bash
make tf-plan PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=network
make tf-apply PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=network
```


## EKSクラスタスタック

```bash
make tf-plan PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=cluster
make tf-apply PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=cluster
```

```bash
CLUSTER_COMPONENT_DIR=$PROJECT_DIR/sample/terraform/components/cluster
CLUSTER_NAME=$(terraform -chdir=$CLUSTER_COMPONENT_DIR output -raw cluster_name)
aws eks update-kubeconfig --name $CLUSTER_NAME
```

## ノードグループスタック

```bash
make tf-plan PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=node-group
make tf-apply PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=node-group
```

## アドオンスタック

```bash
make tf-plan PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=addon
make tf-apply PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=addon
```

## プラグインスタック

```bash
make tf-plan PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=plugin
make tf-apply PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=plugin
```

### metrics-server

- [kubernetes-sigs/metrics-server | GitHub](https://github.com/kubernetes-sigs/metrics-server)
- [metrics-server - Helm Chart | ArtifactHUB](https://artifacthub.io/packages/helm/metrics-server/metrics-server)

```bash
# リポジトリ追加
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/

# リポジトリのアップデート
helm repo update metrics-server

# インストールするチャートのバージョンチェック
CHART_VERSION=$(helm show chart metrics-server/metrics-server | yq -r ".version")
echo $CHART_VERSION


# インストール
helm upgrade --install metrics-server metrics-server/metrics-server \
  --version "3.12.2" \
  --namespace "kube-system" \
  --create-namespace
```

### AWS Load Balancer Controller

- [Install AWS Load Balancer Controller with Helm](https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html)
- [AWS Load Balancer Controller v2.11.0](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.11/)
- [kubernetes-sigs/aws-load-balancer-controller | GitHub](https://github.com/kubernetes-sigs/aws-load-balancer-controller)

```bash
# リポジトリ追加
helm repo add eks https://aws.github.io/eks-charts

# リポジトリのアップデート
helm repo update eks

# インストールするチャートのバージョンチェック
CHART_VERSION=$(helm show chart eks/aws-load-balancer-controller | yq -r ".version")
echo $CHART_VERSION

# インストール
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --version "1.11.0" \
  --namespace "kube-system" \
  --create-namespace \
  --values $PROJECT_DIR/sample/plugin/albc/tmp/values.yaml
```

### Secrets Store CSI Driver

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

### ASCP (aws secrets store csi provider)

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

## サービススタック


```bash
make tf-plan PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=service
make tf-apply PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=service
```

```bash
# デプロイ
kubectl apply -f $PROJECT_DIR/sample/service/keycloak/tmp/app.yaml
```

keycloakはデフォルトでhttpでログインできないので、ログインできるように設定する

```bash
# k9sでkeycloak コンテナのshellを起動
k9s
```

keycloakコンテナのshell内での操作

```bash
# SecretsManager (/<app_name>/<ステージ>/keycloak) のユーザー名とパスワードでログイン
/opt/keycloak/bin/kcadm.sh config credentials \
    --server http://localhost:8080 \
    --realm master \
    --user $KEYCLOAK_ADMIN \
    --password $KEYCLOAK_ADMIN_PASSWORD

# sslRequiredを無効化
/opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE

exit
```

ALBのエンドポイントにアクセスしてログインできることを確認します。

```bash
# ALBのURLを確認
kubectl -n keycloak get ing

# ログイン情報を確認
CLUSTER_NAME=$(terraform -chdir=$PROJECT_DIR/sample/terraform/components/base output -raw cluster_name)
aws secretsmanager get-secret-value --secret-id /$CLUSTER_NAME/keycloak --query "SecretString" --output text | jq "."
```

# ■ 削除

## keycloakの削除

```bash
kubectl delete -f $PROJECT_DIR/sample/service/keycloak/tmp/app.yaml
```

## チャートの削除

```bash
helm uninstall -n kube-system csi-secrets-store
helm uninstall -n kube-system secrets-provider-aws
helm uninstall -n kube-system aws-load-balancer-controller
helm uninstall -n kube-system metrics-server
```

## Terraformリソースの削除

```bash
# プロジェクト名
PROJECT_NAME=tte-mido
# ステージ名
STAGE=dev

make tf-destroy PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=service && \
make tf-destroy PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=plugin && \
make tf-destroy PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=addon && \
make tf-destroy PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=node-group && \
make tf-destroy PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=cluster && \
make tf-destroy PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=network && \
make tf-destroy PROJECT_NAME=$PROJECT_NAME STAGE=$STAGE COMPONENT=base
```
