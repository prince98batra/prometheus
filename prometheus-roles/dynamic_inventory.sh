#!/bin/bash

# Fetch outputs from Terraform
PUBLIC_IP=$(terraform -chdir=../prometheus-terraform/modules/instances output -raw public_instance_ip)
PRIVATE_IP=$(terraform -chdir=../prometheus-terraform/modules/instances output -raw private_instance_ip)

# Generate Ansible inventory file
cat <<EOF
[public]
$PUBLIC_IP ansible_user=ubuntu

[private]
$PRIVATE_IP ansible_user=ubuntu
EOF
