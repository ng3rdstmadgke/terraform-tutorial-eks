Chapter5 リソースの削除
---
[READMEに戻る](../README.md)

# ■ EKS上のリソースを削除

```bash
# 削除
kubectl delete -f scripts/keycloak/tmp/app.yaml
```

# ■ terraformのリソースを削除

```bash
terraform -chdir=terraform/envs/dev/keycloak delete -auto-approve
terraform -chdir=terraform/envs/dev/charts delete -auto-approve
terraform -chdir=terraform/envs/dev/cluster delete -auto-approve
```
