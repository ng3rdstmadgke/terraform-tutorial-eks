Chapter5 リソースの削除
---
[READMEに戻る](../README.md)

# ■ EKS上のリソースを削除

```bash
kubectl delete -f scripts/keycloak/tmp/app.yaml
```

# ■ terraformのリソースを削除

```bash
terraform -chdir=terraform/envs/dev/keycloak destroy -auto-approve && \
terraform -chdir=terraform/envs/dev/charts destroy -auto-approve && \
terraform -chdir=terraform/envs/dev/cluster destroy -auto-approve
```
