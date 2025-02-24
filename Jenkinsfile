pipeline {
    agent any

    tools {
        terraform 'Terraform'  // Ensure this matches the name set in Global Tool Configuration
    }

    environment {
        ANSIBLE_HOST_KEY_CHECKING = 'False'  // To avoid SSH prompt issues
    }

    stages {
        stage('Terraform Init') {
            steps {
                dir('prometheus-terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('prometheus-terraform') {
                    sh 'terraform plan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('prometheus-terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                dir('prometheus-roles') {
                    sh 'chmod +x dynamic_inventory.sh'
                    sh 'ansible-playbook -i dynamic_inventory.sh playbook.yml'
                }
            }
        }

        stage('Terraform Destroy (Optional)') {
            steps {
                input message: 'Do you want to destroy the infrastructure?', ok: 'Destroy'
                dir('prometheus-terraform') {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check the logs for details.'
        }
    }
}
