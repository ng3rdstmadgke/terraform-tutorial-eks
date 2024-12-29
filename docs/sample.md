サンプルのデプロイ手順
---

# ■ terraform, aws-cli, kubectl, helm のインストール手順

devcontainerに含まれています。  
インストール手順は `.devcontainer/Dockerfile` を参照

# ■ デプロイ

```bash
cd sample
```

## EKS クラスタ

```bash
terraform -chdir=terraform/envs/dev/cluster init
terraform -chdir=terraform/envs/dev/cluster plan
terraform -chdir=terraform/envs/dev/cluster apply -auto-approve
```

```bash
CLUSTER_NAME=tutorial-mido-dev
aws eks update-kubeconfig --name $CLUSTER_NAME
```

## チャート

```bash
terraform -chdir=terraform/envs/dev/charts init
terraform -chdir=terraform/envs/dev/charts plan
terraform -chdir=terraform/envs/dev/charts apply -auto-approve
```

# ■ keycloak

## デプロイ

```bash
terraform -chdir=terraform/envs/dev/keycloak init
terraform -chdir=terraform/envs/dev/keycloak plan
terraform -chdir=terraform/envs/dev/keycloak apply -auto-approve
```

```bash
# マニフェスト生成
bash scripts/keycloak/setup.sh

# デプロイ
kubectl apply -f scripts/keycloak/tmp/app.yaml
```

keycloakはデフォルトでhttpでログインできないので、ログインできるように設定する

```bash
# k9sでkeycloak コンテナのshellを起動
k9s
```

keycloakコンテナのshell内での操作

```bash
# SecretsManager (/<app_name>/<ステージ>/keycloak) のユーザー名とパスワードでログイン
$ /opt/keycloak/bin/kcadm.sh config credentials \
    --server http://localhost:8080 \
    --realm master \
    --user $KEYCLOAK_ADMIN \
    --password $KEYCLOAK_ADMIN_PASSWORD

# sslRequiredを無効化
$ /opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE
```

ALBのエンドポイントにアクセスしてログインできることを確認します。

```bash
kubectl -n keycloak get ing
```

## 削除

```bash
# 削除
kubectl delete -f scripts/keycloak/tmp/app.yaml
```

# ■ 削除

```bash
terraform -chdir=terraform/envs/dev/keycloak destroy -auto-approve
terraform -chdir=terraform/envs/dev/charts destroy -auto-approve
terraform -chdir=terraform/envs/dev/cluster destroy -auto-approve
```
