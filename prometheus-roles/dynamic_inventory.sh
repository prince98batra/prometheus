plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  instance-state-name: running
keyed_groups:
  - key: tags.prometheus-server
    prefix: tag
compose:
  ansible_host: public_ip_address
