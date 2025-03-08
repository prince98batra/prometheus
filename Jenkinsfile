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
        stage('Install AWS CLI') {  // Ensures AWS CLI is installed
            steps {
                sh '''
                if ! command -v aws &> /dev/null
                then
                    echo "AWS CLI not found. Installing..."
                    sudo apt update
                    sudo apt install -y unzip
                    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                    unzip awscliv2.zip
                    sudo ./aws/install
                    rm -rf awscliv2.zip aws
                else
                    echo "AWS CLI is already installed."
                fi
                aws --version
                '''
            }
        }

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
        
        stage('Wait for AWS Metadata Propagation') {  // Ensures EC2 public IPs are available
            steps {
                echo "Waiting for AWS to propagate EC2 public IPs..."
                sh 'sleep 60'
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ssh-key-prometheus', keyFileVariable: 'SSH_KEY')]) {
                    dir('prometheus-roles') {
                        sh 'chmod +x dynamic_inventory.sh'
                        sh './dynamic_inventory.sh'
                        sh 'echo Generated Inventory File:'
                        sh 'cat inventory.ini'  // Verify the output of the inventory
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
            echo '⚙️ Pipeline execution completed.'
        }
        success {
            echo '✅ Pipeline executed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check the logs for details.'
        }
        aborted {
            echo '🚫 Pipeline was manually aborted.'
        }
    }
}
