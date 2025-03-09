pipeline {
    agent any

    tools {
        terraform 'Terraform'
        ansible 'Ansible'
    }

    environment {
        TF_VAR_region = 'us-east-1'
        TF_VAR_key_name = 'mykey'
        TF_IN_AUTOMATION = 'true'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        ANSIBLE_REMOTE_USER = 'ubuntu'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
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

        stage('Terraform Validate') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    dir('prometheus-terraform') {
                        sh 'terraform validate'
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

        stage('Terraform Apply or Destroy') {
            steps {
                script {
                    def userChoice = input message: 'Choose Terraform Action:', parameters: [
                        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Select Terraform action')
                    ]

                    def confirm = input message: "Are you sure you want to proceed with ${userChoice}?", parameters: [
                        booleanParam(name: 'CONFIRM', defaultValue: false, description: 'Confirm action')
                    ]

                    if (confirm) {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                            dir('prometheus-terraform') {
                                sh "terraform ${userChoice}"
                            }
                        }
                        applySuccess = (userChoice == 'apply')
                    } else {
                        error "User canceled the Terraform ${userChoice} operation."
                    }
                }
            }
        }

        stage('Install and Configure AWS CLI on EC2') {
            when {
                expression { applySuccess }
            }
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'ssh-key-prometheus', keyFileVariable: 'SSH_KEY'),
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']
                ]) {
                    dir('prometheus-roles') {
                        sh 'chmod +x dynamic_inventory.sh'
                        sh './dynamic_inventory.sh'
                        sh 'echo Generated Inventory File:'
                        sh 'cat inventory.ini'

                        sh '''
                        ansible all -i inventory.ini -m shell -a "
                            sudo apt update -y &&
                            sudo apt install -y unzip curl &&
                            curl -o '/tmp/awscliv2.zip' 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' &&
                            unzip -o '/tmp/awscliv2.zip' -d '/tmp' &&
                            sudo /tmp/aws/install --update &&
                            aws --version &&
                            rm -rf /tmp/aws /tmp/awscliv2.zip
                        " --private-key=$SSH_KEY
                        '''

                        sh '''
                        ansible all -i inventory.ini -m shell -a "
                            mkdir -p ~/.aws &&
                            echo '[default]' > ~/.aws/credentials &&
                            echo 'aws_access_key_id=${AWS_ACCESS_KEY_ID}' >> ~/.aws/credentials &&
                            echo 'aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}' >> ~/.aws/credentials &&
                            echo '[default]' > ~/.aws/config &&
                            echo 'region=us-east-1' >> ~/.aws/config &&
                            chmod 600 ~/.aws/credentials ~/.aws/config &&
                            cat ~/.aws/credentials &&
                            cat ~/.aws/config
                        " --private-key=$SSH_KEY
                        '''
                    }
                }
                echo "Waiting 60 seconds for AWS CLI setup to complete..."
                sh 'sleep 60'
            }
        }

        stage('Run Ansible Playbook') {
            when {
                expression { applySuccess }
            }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ssh-key-prometheus', keyFileVariable: 'SSH_KEY')]) {
                    dir('prometheus-roles') {
                        sh 'chmod +x dynamic_inventory.sh'
                        sh './dynamic_inventory.sh'
                        sh 'echo Generated Inventory File:'
                        sh 'cat inventory.ini'
                        sh 'ansible-playbook -i inventory.ini playbook.yml --private-key=$SSH_KEY'
                    }
                }
            }
        }
    }

    post {
        always {
            echo ':gear: Pipeline execution completed.'
        }
        success {
            echo ':white_check_mark: Pipeline executed successfully!'
        }
        failure {
            echo ':x: Pipeline failed. Check the logs for details.'
        }
        aborted {
            echo ':no_entry_sign: Pipeline was manually aborted.'
        }
    }
}
