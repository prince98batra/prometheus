resource "aws_instance" "public_instance_1" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id_1
  key_name               = var.key_name
  vpc_security_group_ids = [var.public_sg_id_1]

  tags = {
    Name        = "prometheus-instance-zone-1"
    fetch_name  = "prometheus-instance-1"
  }
}

resource "aws_instance" "public_instance_2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id_2
  key_name               = var.key_name
  vpc_security_group_ids = [var.public_sg_id_2]

  tags = {
    Name        = "prometheus-instance-zone-2"
    fetch_name  = "prometheus-instance-2"
  }
}

output "public_instance_ip_1" {
  value = aws_instance.public_instance_1.public_ip
}
output "public_instance_ip_2" {
  value = aws_instance.public_instance_2.public_ip
}
output "fetch_name_1" {
  value = aws_instance.public_instance_1.tags["fetch_name"]
}

output "fetch_name_2" {
  value = aws_instance.public_instance_2.tags["fetch_name"]
}
