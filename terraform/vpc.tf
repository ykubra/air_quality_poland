
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
    Name = "terraform_public_subnet"
  }
}

# Create a private subnet
resource "aws_subnet" "PrivateSubnet1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2c"
  tags = {
    Name = "terraform_private_subnet_1"
  }
}
resource "aws_subnet" "PrivateSubnet2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "terraform_private_subnet_2"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "igw"{
  vpc_id = aws_vpc.myvpc.id
}
# Create route tables
resource "aws_route_table" "PublicRT"{
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "PrivateRT"{
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

# Route table association public subnet
resource "aws_route_table_association" "PublicRTassociation"{
  subnet_id = aws_subnet.PublicSubnet.id
  route_table_id = aws_route_table.PublicRT.id
}
# Route table association private subnet
resource "aws_route_table_association" "PrivateRTassociation1"{
  subnet_id = aws_subnet.PrivateSubnet1.id
  route_table_id = aws_route_table.PrivateRT.id
}
resource "aws_route_table_association" "PrivateRTassociation2"{
  subnet_id = aws_subnet.PrivateSubnet2.id
  route_table_id = aws_route_table.PrivateRT.id
}

# Create Elastic IP address
resource "aws_eip" "eip" {  
  vpc      = true
}

# Create nat gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip.id
  connectivity_type = "public"
  subnet_id     = aws_subnet.PublicSubnet.id

  tags = {
    Name = "terraform-nat-gateway"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}