output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_id_1" {
  value = module.networking.public_subnet_id_1
}

output "public_subnet_id_2" {
  value = module.networking.public_subnet_id_2
}

output "public_sg_id_1" {
  value = module.security.public_sg_id_1
}

output "public_sg_id_2" {
  value = module.security.public_sg_id_2
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
