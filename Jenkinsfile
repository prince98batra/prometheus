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

        stage('User Input - Choose Action') {
            steps {
                script {
                    def userInput = input message: 'Choose the action to perform:', parameters: [
                        choice(name: 'ACTION', choices: ['Apply', 'Destroy', 'Skip'], description: 'Select whether to apply, destroy, or skip.')
                    ]

                    if (userInput == 'Apply') {
                        currentBuild.result = 'SUCCESS'  // Proceed with apply if the user chooses Apply
                    } else if (userInput == 'Destroy') {
                        currentBuild.result = 'SUCCESS'  // Proceed with destroy if the user chooses Destroy
                    } else {
                        currentBuild.result = 'SUCCESS'  // Skip if the user chooses Skip
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { return currentBuild.result == 'SUCCESS' && input == 'Apply' }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    dir('prometheus-terraform') {
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Run Ansible Playbook') {
            when {
                expression { return currentBuild.result == 'SUCCESS' && input == 'Apply' }
            }
            steps {
                withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                    withCredentials([sshUserPrivateKey(credentialsId: 'ssh-key-prometheus', keyFileVariable: 'SSH_KEY')]) {
                        dir('prometheus-roles') {
                            sh '''
                            echo "Waiting for EC2 instance to initialize..."
                            sleep 60
                            echo "Running Ansible Playbook..."
                            ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i aws_ec2.yml playbook.yml --private-key=$SSH_KEY -u ubuntu
                            '''
                        }
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { return currentBuild.result == 'SUCCESS' && input == 'Destroy' }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    dir('prometheus-terraform') {
                        sh 'terraform destroy -auto-approve'
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
