/**
 * metrics-serverチャートをインストールします。
 * - Kubernetes メトリクスサーバーのインストール | AWS: https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/metrics-server.html
 * - metrics-server | ArtifactHUB: https://artifacthub.io/packages/helm/metrics-server/metrics-server
 */

//helm_release - helm - terraform: https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.1"
  namespace  = "kube-system"
  create_namespace = true
}