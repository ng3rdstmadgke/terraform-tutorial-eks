# AWS Load Balancer Controller

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