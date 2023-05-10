# Create subnet group for RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
 name       = "rds_subnet_group"
  subnet_ids = [aws_subnet.PublicSubnet.id, aws_subnet.PrivateSubnet.id]
  
  tags = {
   Name = "terraform_rds_subnet_group"
 }
}

# Create RDS mysql db
resource "aws_db_instance" "energy_consumption_db" {
  db_name              = "energyconsumptiondatabase"
  engine               = "mysql"
  engine_version       = "8.0.32"
  allocated_storage    = 20
  storage_type         = "gp2"
  identifier           = "mydb"
  instance_class       = "db.t3.micro"
  skip_final_snapshot  = true
  username             = "admin"
  password             = random_password.rds_password.result

  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_rds.id]

  tags = {
        Name ="terraform_energy_consumption_database"
  }
}