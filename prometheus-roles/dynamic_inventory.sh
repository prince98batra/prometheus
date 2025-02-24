#!/bin/bash

# Fetch Terraform outputs for public and private instance IPs
PUBLIC_IP=$(terraform -chdir=../prometheus-terraform output -raw public_instance_ip)
PRIVATE_IP=$(terraform -chdir=../prometheus-terraform output -raw private_instance_ip)

# Generate Ansible inventory file
cat <<EOF > inventory.ini
[public]
$PUBLIC_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/mykey.pem

[private]
$PRIVATE_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/mykey.pem ansible_ssh_common_args='-o ProxyCommand="ssh -i ~/.ssh/mykey.pem -W %h:%p ubuntu@$PUBLIC_IP"'
EOF
