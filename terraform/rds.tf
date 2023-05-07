
# create subnets
resource "aws_db_subnet_group" "my-subnet-group" {
 name       = "terraform-subnet-group"
  subnet_ids = [aws_subnet.PublicSubnet.id, aws_subnet.PrivateSubnet.id]
  
  tags = {
   Name = "My DB subnet group"
 }
}

# create rds mysql db
resource "aws_db_instance" "myrds" {
  db_name              = "airqualitydatabase"
  engine               = "mysql"
  engine_version       = "8.0.32"
  allocated_storage    = 20
  storage_type         = "gp2"
  identifier           = "mydb"
  instance_class       = "db.t3.micro"
  skip_final_snapshot  = true
  username             = "admin"
  password             = random_password.rds_password.result

  db_subnet_group_name = aws_db_subnet_group.my-subnet-group.name
  vpc_security_group_ids = [aws_security_group.sg_rds.id]

  tags = {
        Name ="Myrdsdb"
  }
}