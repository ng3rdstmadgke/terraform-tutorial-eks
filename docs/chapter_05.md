Chapter5 リソースの削除
---
[READMEに戻る](../README.md)

# ■ EKS上のリソースを削除

```bash
CLUSTER_NAME=$(terraform -chdir=terraform/envs/dev/cluster output -raw cluster_name)

# ~/.kube/configを生成
aws eks update-kubeconfig --name $CLUSTER_NAME

kubectl delete -f scripts/keycloak/tmp/app.yaml
```

# ■ terraformのリソースを削除

```bash
terraform -chdir=terraform/envs/dev/keycloak destroy -auto-approve && \
terraform -chdir=terraform/envs/dev/charts destroy -auto-approve && \
terraform -chdir=terraform/envs/dev/cluster destroy -auto-approve
```
