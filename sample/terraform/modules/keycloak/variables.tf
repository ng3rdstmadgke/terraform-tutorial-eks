variable "cluster_name" {}
variable "cluster_oidc_provider" {}
variable "cluster_security_group_id" {}
variable "alb_ingress_sg" {}
variable "vpc_id" {}
variable "private_subnet_ids" {}
variable "project_dir" {}

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