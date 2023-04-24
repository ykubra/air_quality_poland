resource "aws_secretsmanager_secret" "rds_secret" {
  name = "rds-proxy-secret"
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id     = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    "username"             = "admin"
    "password"             = "passw0rd!123"
    "engine"               = "mysql"
    "host"                 = aws_db_instance.myrds.address
    "port"                 = 3306
    "dbInstanceIdentifier" = aws_db_instance.myrds.id
  })
}