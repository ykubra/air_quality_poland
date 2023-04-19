
# Create a VPC
resource "aws_vpc" "myvpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
    Name = "Terraform-VPC"
  }
}

# Create a public subnet
resource "aws_subnet" "PublicSubnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2b"
  tags = {
    Name = "terraform-subnet_1"
  }
}

# Create a private subnet
resource "aws_subnet" "PrivateSubnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2c"
  tags = {
    Name = "terraform-subnet"
  }
}

# create an internet gateway
resource "aws_internet_gateway" "igw"{
  vpc_id = aws_vpc.myvpc.id
}
# create route table
resource "aws_route_table" "PublicRT"{
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
# route table association public subnet
resource "aws_route_table_association" "PublicRTassociation"{
  subnet_id = aws_subnet.PublicSubnet.id
  route_table_id = aws_route_table.PublicRT.id
}