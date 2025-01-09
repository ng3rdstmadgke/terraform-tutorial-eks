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
CLUSTER_NAME=$(terraform -chdir=$PROJECT_DIR/tutorial/terraform/components/base output -raw cluster_name)
COMMON_BACKEND_CONFIG=$PROJECT_DIR/tutorial/terraform/components/tfvars/dev.backend.tfvars
COMPONENTS=("service" "plugin" "addon" "node-group" "cluster" "network" "base")
SCRIPT_PATH=/tmp/${CLUSTER_NAME}-destroy.sh

# リソースを削除するスクリプトを生成
cat <<EOF > $SCRIPT_PATH
#!/bin/bash

set -e
EOF

for COMPONENT_NAME in ${COMPONENTS[@]}; do
  COMPONENT_DIR=$PROJECT_DIR/tutorial/terraform/components/$COMPONENT_NAME
  COMPONENT_TFVARS=$COMPONENT_DIR/tfvars/dev.tfvars
  echo terraform -chdir=$COMPONENT_DIR init \
    -reconfigure \
    -backend-config $COMMON_BACKEND_CONFIG \
    -backend-config \"key=$CLUSTER_NAME/$COMPONENT_NAME/terraform.tfstate\"
  echo terraform -chdir=$COMPONENT_DIR destroy -var-file $COMPONENT_TFVARS -auto-approve
done >> $SCRIPT_PATH

# 生成されたスクリプトの確認
cat $SCRIPT_PATH

# リソースの削除
bash $SCRIPT_PATH
```
