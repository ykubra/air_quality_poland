/*resource "aws_network_interface" "eni" {
  subnet_id       = aws_subnet.PrivateSubnet.id
  private_ips     = ["10.0.0.50"]
  security_groups = [aws_security_group.sg_lambda.id]

}
resource "aws_eip" "eip" {
  vpc = true

  network_interface = aws_network_interface.eni.id
  associate_with_private_ip = "10.0.0.12"
  depends_on                = [aws_internet_gateway.igw]
}*/