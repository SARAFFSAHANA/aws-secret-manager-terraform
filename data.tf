data "aws_secretsmanager_secret" "mysql_secret" {
  name = "prod/mysql/db-credentials"
}

data "aws_secretsmanager_secret_version" "mysql_secret_version" {
  secret_id = data.aws_secretsmanager_secret.mysql_secret.id
}

locals {
  mysql_credentials = jsondecode(
    data.aws_secretsmanager_secret_version.mysql_secret_version.secret_string
  )
}


/*This reads:

username

password

Securely from Secrets Manager. */