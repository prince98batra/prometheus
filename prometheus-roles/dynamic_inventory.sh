#!/bin/bash

# Fetch Terraform outputs directly
PUBLIC_IP=$(terraform output -raw public_instance_ip)
PRIVATE_IP=$(terraform output -raw private_instance_ip)

# Debugging: Print IPs to verify
echo "Public IP: $PUBLIC_IP"
echo "Private IP: $PRIVATE_IP"

# Create dynamic inventory for Ansible
cat <<EOF > inventory.ini
[public]
$PUBLIC_IP ansible_user=ubuntu ansible_ssh_private_key_file=$SSH_KEY

[private]
$PRIVATE_IP ansible_user=ubuntu ansible_ssh_private_key_file=$SSH_KEY ansible_ssh_common_args='-o ProxyCommand="ssh -i $SSH_KEY -W %h:%p ubuntu@$PUBLIC_IP"'
EOF
