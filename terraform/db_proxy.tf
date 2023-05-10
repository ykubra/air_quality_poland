# Create default target group
resource "aws_db_proxy_default_target_group" "rds_proxy_target_group" {
  db_proxy_name = aws_db_proxy.db_proxy.name

  connection_pool_config {
    connection_borrow_timeout = 120
    max_connections_percent = 100
  }
}

# Create proxy target
resource "aws_db_proxy_target" "rds_proxy_target" {
  db_instance_identifier = aws_db_instance.energy_consumption_db.id
  db_proxy_name          = aws_db_proxy.db_proxy.name
  target_group_name      = aws_db_proxy_default_target_group.rds_proxy_target_group.name
}

# Create RDS proxy
resource "aws_db_proxy" "db_proxy" {
  name                 = "terraform-proxy-db"
  debug_logging          = false
  engine_family          = "MYSQL"
  idle_client_timeout    = 1800
  require_tls            = false
  role_arn               = aws_iam_role.rds_proxy_iam_role.arn
  vpc_security_group_ids = [aws_security_group.sg_rds_proxy.id]
  vpc_subnet_ids         = [aws_subnet.PrivateSubnet1.id, aws_subnet.PrivateSubnet2.id]

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.rds_secret.arn
  }
}
