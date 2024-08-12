/**
 * Secrets Store CSI Driver チャートのインストール
 *
 * - Kubernetes Secrets Store CSI Driver
 *   https://secrets-store-csi-driver.sigs.k8s.io/
 * - Amazon Elastic Kubernetes Service で AWS Secrets Manager シークレットを使用する
 *   https://docs.aws.amazon.com/ja_jp/secretsmanager/latest/userguide/integrating_csi_driver.html
 */
resource "helm_release" "csi_secrets_store" {
  //helm_release - helm - terraform: https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
  name       = "csi-secrets-store"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = "1.4.4"  # helm search repo secrets-store-csi-driver
  namespace  = "kube-system"
  create_namespace = true

  // Option Values - Secrets Store CSI Driver: https://secrets-store-csi-driver.sigs.k8s.io/getting-started/installation.html#optional-values
  set {
    // KubernetesのSecretオブジェクトへの同期を有効化
    name = "syncSecret.enabled"
    value = true
  }

  set {
    // シークレット情報変更時のローテーションを有効化
    name = "enableSecretRotation"
    value = true
  }
}

/**
 * ASCP (aws secrets store csi provider) チャートのインストール
 *
 * - secrets-store-csi-driver-provider-aws | GitHub
 *   https://github.com/aws/secrets-store-csi-driver-provider-aws
 * - Amazon Elastic Kubernetes Service で AWS Secrets Manager シークレットを使用する
 *   https://docs.aws.amazon.com/ja_jp/secretsmanager/latest/userguide/integrating_csi_driver.html
 */
resource "helm_release" "secrets_provider_aws" {
  //helm_release - helm - terraform: https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
  name       = "secrets-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  version    = "0.3.9"  # helm search repo secrets-store-csi-driver-provider-aws
  namespace  = "kube-system"
  create_namespace = true

  depends_on = [
    helm_release.csi_secrets_store
  ]
}
