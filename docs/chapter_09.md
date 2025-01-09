Chapter9 リソースの削除
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
terraform -chdir=$PROJECT_DIR/tutorial/terraform/components/service destroy -auto-approve && \
terraform -chdir=$PROJECT_DIR/tutorial/terraform/components/plugin destroy -auto-approve && \
terraform -chdir=$PROJECT_DIR/tutorial/terraform/components/addon destroy -auto-approve && \
terraform -chdir=$PROJECT_DIR/tutorial/terraform/components/node-group destroy -auto-approve && \
terraform -chdir=$PROJECT_DIR/tutorial/terraform/components/cluster destroy -auto-approve && \
terraform -chdir=$PROJECT_DIR/tutorial/terraform/components/network destroy -auto-approve && \
terraform -chdir=$PROJECT_DIR/tutorial/terraform/components/base destroy -auto-approve
```
