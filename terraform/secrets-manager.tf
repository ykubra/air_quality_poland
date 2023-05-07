resource "random_password" "rds_password"{
  length           = 16
  special          = true
  override_special = "_!%^"
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name = "rds-proxy-secret"
}



resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id     = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    "username"             = aws_db_instance.myrds.username
    "password"             = random_password.rds_password.result
    "db_name"              = aws_db_instance.myrds.db_name
    "engine"               = aws_db_instance.myrds.engine
    "host"                 = aws_db_proxy.db_proxy.endpoint
    "port"                 = aws_db_instance.myrds.port
    "dbInstanceIdentifier" = aws_db_instance.myrds.id
  })
}