resource "aws_instance" "public_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_id
  key_name      = var.key_name
  vpc_security_group_ids = [var.public_sg_id]
  tags = { Name = "prometheus-server" }
}


output "public_instance_ip" {
  value = aws_instance.public_instance.public_ip
}

