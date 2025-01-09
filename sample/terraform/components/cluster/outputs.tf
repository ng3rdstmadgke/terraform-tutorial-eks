output "cluster_name" {
  value = module.cluster.eks_cluster.name
}

output "version" {
  value = module.cluster.eks_cluster.version
}

output "oidc_provider" {
  // AWS CLIで確認する場合: aws eks describe-cluster --name クラスタ名 --output text --query "cluster.identity.oidc.issuer"
  value = replace(module.cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")
}

output "cluster_security_group_id" {
  value = module.cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

output "api_endpoint" {
  value = module.cluster.eks_cluster.endpoint
}

output "cluster_certificate" {
  value = module.cluster.eks_cluster.certificate_authority[0].data
}

output "subnet_ids" {
  value = module.cluster.eks_cluster.vpc_config[0].subnet_ids
}
