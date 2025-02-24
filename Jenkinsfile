pipeline {
    agent any

    tools {
        terraform 'Terraform'  // Match this with the name set in Global Tool Configuration
        ansible 'Ansible'      // Match this with the name set in Global Tool Configuration
    }

    environment {
        TF_VAR_region = 'us-east-1'                 // Terraform region variable
        TF_VAR_key_name = 'mykey'                   // Terraform key pair
        TF_IN_AUTOMATION = 'true'                   // Disable interactive prompts for Terraform
        ANSIBLE_HOST_KEY_CHECKING = 'False'         // Disable SSH prompt for Ansible
        ANSIBLE_REMOTE_USER = 'ubuntu'              // Remote SSH user for Ansible
    }

    stages {
        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    dir('prometheus-terraform') {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    dir('prometheus-terraform') {
                        sh 'terraform plan'
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    dir('prometheus-terraform') {
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Run Ansible Playbook') {
    steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'aws-ssh-key', keyFileVariable: 'SSH_KEY')]) {
            dir('prometheus-roles') {
                sh 'chmod +x dynamic_inventory.sh'
                sh './dynamic_inventory.sh'  // Generate inventory file
                sh 'ansible-playbook -i inventory.ini playbook.yml --private-key=$SSH_KEY'
            }
        }
    }
}
    }

    post {
        always {
            input message: 'Do you want to destroy the infrastructure?', ok: 'Destroy'
            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                dir('prometheus-terraform') {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
        success {
            echo '✅ Pipeline executed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check the logs for details.'
        }
    }
}
