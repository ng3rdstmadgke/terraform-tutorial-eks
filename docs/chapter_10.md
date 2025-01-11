Chapter10 リソースの削除
---
[READMEに戻る](../README.md)

# ■ 削除

## keycloakの削除

```bash
kubectl delete -f $PROJECT_DIR/tutorial/service/keycloak/tmp/app.yaml
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
PROJECT_NAME=プロジェクト名
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
