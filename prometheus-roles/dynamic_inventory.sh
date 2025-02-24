#!/bin/bash

# Fetching IPs directly from the instances module
PUBLIC_IP=$(terraform -chdir=../prometheus-terraform output -raw instances_public_instance_ip)
PRIVATE_IP=$(terraform -chdir=../prometheus-terraform output -raw instances_private_instance_ip)

# Generate dynamic inventory
cat <<EOF
[public]
$PUBLIC_IP ansible_user=ubuntu

[private]
$PRIVATE_IP ansible_user=ubuntu
EOF
