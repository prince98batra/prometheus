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
        withCredentials([sshUserPrivateKey(credentialsId: 'ssh-key-prometheus', keyFileVariable: 'SSH_KEY')]) {
            dir('prometheus-roles') {
                sh '''
                echo "Generating Dynamic Inventory..."
                ansible-inventory -i dynamic_inventory.yml --list

                echo "Fetching target instance..."
                TARGET_IP=$(ansible-inventory -i dynamic_inventory.yml --list | jq -r '.["_meta"].hostvars | keys[]')

                echo "Connecting to ${TARGET_IP} and running playbook..."
                ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${TARGET_IP}, playbook.yml --private-key=$SSH_KEY -u ubuntu
                '''
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
