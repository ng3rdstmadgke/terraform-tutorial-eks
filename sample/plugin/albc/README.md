# AWS Load Balancer Controller

- [AWS Load Balancer Controller v2.11.0](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.11/)
- [kubernetes-sigs/aws-load-balancer-controller | GitHub](https://github.com/kubernetes-sigs/aws-load-balancer-controller)


## インストール手順

- [Install AWS Load Balancer Controller with Helm](https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html)


リポジトリ追加

```bash
helm repo add eks https://aws.github.io/eks-charts
```

リポジトリのアップデート


```bash
helm repo update eks
```


インストール


```bash
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --version "1.11.0" \
  --namespace "kube-system" \
  --create-namespace \
  --values ./tmp/values.yaml
```