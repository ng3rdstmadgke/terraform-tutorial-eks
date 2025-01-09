variable "cluster_name" {
  type = string
  description = "EKSクラスタ名"
}
variable "cluster_oidc_provider" {
  type = string
  description = "EKSクラスタのOIDCプロバイダ"
}
variable "cluster_security_group_id" {
  type = string
  description = "EKSクラスタのクラスタセキュリティグループID"
}
variable "alb_ingress_sg" {
  type = string
  description = "ALB Ingress ControllerのセキュリティグループID"
}
variable "vpc_id" {
  type = string
  description = "VPC ID"
}
variable "private_subnet_ids" {
  type = list(string)
  description = "プライベートサブネットID"
}
variable "project_dir" {
  type = string
  description = "プロジェクトディレクトリの絶対パス"
}

locals {
  account_id = data.aws_caller_identity.this.account_id
  aws_region = data.aws_region.this.name
  namespace = "keycloak"
  service_account = "keycloak"
  db_user = "admin"
  db_name = "keycloak"
}


data "aws_caller_identity" "this" {}

data "aws_region" "this" {}