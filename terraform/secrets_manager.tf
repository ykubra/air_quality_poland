# Generate random password for RDS
resource "random_password" "rds_password"{
  length           = 16
  special          = true
  override_special = "_!%^"
}

# Create RDS secret to fetch it from Lambda
resource "aws_secretsmanager_secret" "rds_secret" {
  name = "rds-proxy-secret"
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id     = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    "username"             = aws_db_instance.energy_consumption_db.username
    "password"             = random_password.rds_password.result
    "db_name"              = aws_db_instance.energy_consumption_db.db_name
    "engine"               = aws_db_instance.energy_consumption_db.engine
    "host"                 = aws_db_proxy.db_proxy.endpoint
    "port"                 = aws_db_instance.energy_consumption_db.port
    "dbInstanceIdentifier" = aws_db_instance.energy_consumption_db.id
  })
}