# metrics-server

- [kubernetes-sigs/metrics-server | GitHub](https://github.com/kubernetes-sigs/metrics-server)
- [metrics-server - Helm Chart | ArtifactHUB](https://artifacthub.io/packages/helm/metrics-server/metrics-server)

## インストール手順

リポジトリの追加

```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
```

インストール

```bash
helm upgrade --install metrics-server metrics-server/metrics-server \
  --version "3.12.2" \
  --namespace "kube-system" \
  --create-namespace
```