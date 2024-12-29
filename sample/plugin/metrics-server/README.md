# metrics-server

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