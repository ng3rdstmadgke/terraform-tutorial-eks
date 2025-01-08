/**
 * サービスアカウントに紐づけるIAMロールの作成
 */
resource "aws_iam_role" "keycloak" {
  name = "${var.cluster_name}-KeycloakRole"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17"
    "Statement": {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${local.account_id}:oidc-provider/${var.cluster_oidc_provider}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "${var.cluster_oidc_provider}:sub": "system:serviceaccount:${local.namespace}:${local.service_account}",
          "${var.cluster_oidc_provider}:aud": "sts.amazonaws.com"
        }
      }
    }
  })
}

resource "aws_iam_policy" "keycloak" {
  name = "${var.cluster_name}-KeycloakPolicy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        "Resource": [
          "arn:aws:secretsmanager:${local.aws_region}:${local.account_id}:secret:/${var.cluster_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "keycloak" {
  role = aws_iam_role.keycloak.name
  policy_arn = aws_iam_policy.keycloak.arn
}

/**
 * Keycloakのadminログイン情報を保持する SecretsManager
 */
resource "random_password" "keycloak_user" {
  // https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password

  length           = 32
  lower            = true  # 小文字を文字列に含める
  numeric          = true  # 数値を文字列に含める
  upper            = true  # 大文字を文字列に含める
  special          = false # 記号を文字列に含める
}

resource "random_password" "keycloak_password" {
  length           = 32
  lower            = true  # 小文字を文字列に含める
  numeric          = true  # 数値を文字列に含める
  upper            = true  # 大文字を文字列に含める
  special          = true  # 記号を文字列に含める
  override_special = "@_=+-"  # 記号で利用する文字列を指定 (default: !@#$%&*()-_=+[]{}<>:?)
}

resource "aws_secretsmanager_secret" "keycloak_admin_user" {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret

  name = "/${var.cluster_name}/keycloak"
  recovery_window_in_days = 0
  force_overwrite_replica_secret = true
}

resource "aws_secretsmanager_secret_version" "keycloak_admin_user" {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version

  secret_id = aws_secretsmanager_secret.keycloak_admin_user.id
  secret_string = jsonencode({
    user = random_password.keycloak_user.result
    password = random_password.keycloak_password.result
  })
}

/**
 * RDS
 */
resource "aws_security_group" "app_db_sg" {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

  name = "${var.cluster_name}-keycloak-db"
  vpc_id = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [var.cluster_security_group_id]
  }
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    // EKSクラスタのセキュリティグループからのアクセスを許可
    security_groups = [var.cluster_security_group_id]
  }
  tags = {
    "Name" = "${var.cluster_name}-keycloak-db"
  }
}

resource "aws_db_parameter_group" "app_db_pg" {
  // MySQLのパラメータの確認: aws rds describe-engine-default-parameters --db-parameter-group-family mysql8.0
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group

  name = "${var.cluster_name}-keycloak-db"
  family = "mysql8.0"
  parameter {
    name = "character_set_client"
    value = "utf8mb4"
  }
  parameter {
    name = "character_set_connection"
    value = "utf8mb4"
  }
  parameter {
    name = "character_set_database"
    value = "utf8mb4"
  }
  parameter {
    name = "character_set_filesystem"
    value = "utf8mb4"
  }
  parameter {
    name = "character_set_results"
    value = "utf8mb4"
  }
  parameter {
    name = "character_set_server"
    value = "utf8mb4"
  }
  parameter {
    name = "collation_connection"
    value = "utf8mb4_bin"
  }
  parameter {
    name = "collation_server"
    value = "utf8mb4_bin"
  }
}

resource "aws_db_subnet_group" "app_db_subnet_group" {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group

  name       = "${var.cluster_name}-keycloak-db"
  subnet_ids = var.private_subnet_ids
}

resource "random_password" "db_password" {
  length           = 16
  lower            = true  # 小文字を文字列に含める
  numeric          = true  # 数値を文字列に含める
  upper            = true  # 大文字を文字列に含める
  special          = true  # 記号を文字列に含める
  override_special = "@_=+-"  # 記号で利用する文字列を指定 (default: !@#$%&*()-_=+[]{}<>:?)
}

resource "aws_db_instance" "app_db" {
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance

  identifier = "${var.cluster_name}-keycloak-db"
  storage_encrypted = true
  engine               = "mysql"
  allocated_storage    = 20
  max_allocated_storage = 100
  db_name              = local.db_name
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.app_db_subnet_group.name
  backup_retention_period = 30
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  multi_az = false
  parameter_group_name = aws_db_parameter_group.app_db_pg.name
  port = 3306
  vpc_security_group_ids = [aws_security_group.app_db_sg.id]
  storage_type = "gp3"
  network_type = "IPV4"
  username = local.db_user
  password = random_password.db_password.result
  skip_final_snapshot  = true
  deletion_protection = false
  lifecycle {
    // terraformから削除されたくない場合はコメントイン
    #prevent_destroy = true
  }
}


/**
 * RDS のログイン情報を保持する SecretsManager
 */
resource "aws_secretsmanager_secret" "app_db_secret" {
  name = "/${var.cluster_name}/db"
  recovery_window_in_days = 0
  force_overwrite_replica_secret = true
}

resource "aws_secretsmanager_secret_version" "app_db_secret_version" {
  secret_id = aws_secretsmanager_secret.app_db_secret.id
  secret_string = jsonencode({
    db_user = local.db_user
    db_password = random_password.db_password.result
    db_host = aws_db_instance.app_db.address
    db_port = tostring(aws_db_instance.app_db.port)
    db_name = local.db_name
  })
}

/**
 * マニフェストファイルの生成
 */
resource "local_file" "keycloak_manifest" {
  filename = "${var.project_dir}/service/keycloak/tmp/app.yaml"
  content = templatefile(
    "${path.module}/app.yaml",
    {
      namespace = local.namespace,
      service_account = local.service_account,
      role_arn = aws_iam_role.keycloak.arn,
      db_secret_name = aws_secretsmanager_secret.app_db_secret.name,
      user_secret_name = aws_secretsmanager_secret.keycloak_admin_user.name
      alb_ingress_sg = var.alb_ingress_sg
    }
  )
}