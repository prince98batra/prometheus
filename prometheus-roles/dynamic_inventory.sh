#!/bin/bash

# Fetch IPs from Terraform output
public_ip=$(terraform -chdir=../prometheus-terraform output -raw public_instance_ip)
private_ip=$(terraform -chdir=../prometheus-terraform output -raw private_instance_ip)

# Generate Ansible dynamic inventory
cat <<EOF > inventory.ini
[public]
$public_ip ansible_user=ubuntu ansible_ssh_private_key_file=$SSH_KEY

[private]
$private_ip ansible_user=ubuntu ansible_ssh_private_key_file=$SSH_KEY ansible_ssh_common_args='-o ProxyCommand="ssh -i $SSH_KEY -W %h:%p ubuntu@$public_ip"'
EOF
