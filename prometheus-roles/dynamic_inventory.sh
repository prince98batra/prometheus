#!/bin/bash

# Fetch IPs from Terraform output
public_ip=$(terraform -chdir=../prometheus-terraform output -raw public_instance_ip)

# Generate Ansible dynamic inventory
cat <<EOF > inventory.ini
[public]
$public_ip ansible_user=ubuntu ansible_ssh_private_key_file=$SSH_KEY

EOF
