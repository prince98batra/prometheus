provider "aws" {
  region = "us-east-1"
}

module "networking" {
  source = "./modules/networking"
  vpc_cidr = "192.168.0.0/16"
  public_subnets  = ["192.168.10.0/24", "192.168.20.0/24"]
}

module "security" {
  source = "./modules/security"
  vpc_id = module.networking.vpc_id
}

module "instances" {
  source = "./modules/instances"
  ami_id = "ami-0e1bed4f06a3b463d"
  instance_type = "t2.micro"
  key_name = "mykey"
  public_subnet_id_1  = module.networking.public_subnet_id_1
  public_subnet_id_2  = module.networking.public_subnet_id_2
  public_sg_id_1  = module.security.public_sg_id_1
  public_sg_id_2  = module.security.public_sg_id_2
}

output "public_instance_ip_1" {
  value = module.instances.public_instance_ip_1
}

output "public_instance_ip_2" {
  value = module.instances.public_instance_ip_2
}

output "fetch_name_1" {
  value = module.instances.fetch_name_1
}

output "fetch_name_2" {
  value = module.instances.fetch_name_2
}
