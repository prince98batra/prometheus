pipeline {
    agent any

    tools {
        terraform 'Terraform'  // Matches the name set in Global Tool Configuration
        ansible 'Ansible'      // Matches the name set in Global Tool Configuration
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

        stage('Wait for AWS Metadata Propagation') {  
            steps {
                echo "Waiting for AWS to propagate EC2 public IPs..."
                sh 'sleep 60'
            }
        }

        stage('Install AWS CLI') {
            steps {
                script {
                    def cli_check = sh(script: "aws --version || echo 'NOT_INSTALLED'", returnStdout: true).trim()
                    if (cli_check.contains("NOT_INSTALLED")) {
                        echo "AWS CLI not found. Installing..."
                        sh '''
                            sudo apt update -y
                            sudo apt install -y unzip curl
                            sudo curl -o "/tmp/awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
                            sudo unzip -o "/tmp/awscliv2.zip" -d "/tmp"
                            sudo /tmp/aws/install --update
                            aws --version
                            sudo rm -rf /tmp/aws /tmp/awscliv2.zip
                        '''
                    } else {
                        echo "AWS CLI is already installed."
                    }
                }
            }
        }

        stage('Configure AWS CLI') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    echo "Configuring AWS CLI with Jenkins credentials..."
                    sh '''
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set region us-east-1
                        aws configure list
                    '''
                }
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
