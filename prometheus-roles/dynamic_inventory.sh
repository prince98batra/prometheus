#!/bin/bash

# Initialize Terraform providers (Fixes the plugin issue)
terraform -chdir=../prometheus-terraform/modules/instances init -upgrade -reconfigure

# Fetch outputs from Terraform
PUBLIC_IP=$(terraform -chdir=../prometheus-terraform/modules/instances output -raw public_instance_ip)
PRIVATE_IP=$(terraform -chdir=../prometheus-terraform/modules/instances output -raw private_instance_ip)

# Generate Ansible inventory file
cat <<EOL > inventory.ini
[public]
$PUBLIC_IP ansible_user=ubuntu ansible_ssh_private_key_file=$SSH_KEY

[private]
$PRIVATE_IP ansible_user=ubuntu ansible_ssh_private_key_file=$SSH_KEY ansible_ssh_common_args='-o ProxyCommand="ssh -i $SSH_KEY -W %h:%p ubuntu@$PUBLIC_IP"'
EOL
