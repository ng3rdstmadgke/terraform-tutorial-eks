output "namespace" {
  value = local.namespace
}

output "service_account" {
  value = local.service_account
}

output "keycloak_user_secret" {
  value = aws_secretsmanager_secret.keycloak_admin_user.name
}

output "keycloak_db_secret" {
  value = aws_secretsmanager_secret.app_db_secret.name
}
