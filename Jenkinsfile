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

        stage('User Input - Choose Action') {
            steps {
                script {
                    def userInput = input message: 'Choose the action to perform:', parameters: [
                        choice(name: 'ACTION', choices: ['Apply', 'Destroy'], description: 'Select whether to apply or destroy.')
                    ]
                    env.ACTION = userInput
                }
            }
        }

        stage('Confirm Action') {
            steps {
                script {
                    def confirmation = input message: "Do you want to proceed with ${env.ACTION}?", parameters: [
                        choice(name: 'CONFIRMATION', choices: ['yes', 'no'], description: 'Type "yes" to proceed or "no" to cancel.')
                    ]
                    if (confirmation != 'yes') {
                        error("Pipeline aborted by user.")
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { return env.ACTION == 'Apply' }
            }
            steps {
                echo "You have chosen to apply the Terraform changes."
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    dir('prometheus-terraform') {
                        script {
                            def userInput = input message: 'Type "yes" to confirm Terraform Apply:', parameters: [
                                string(name: 'CONFIRM_APPLY', defaultValue: '', description: 'Only "yes" will proceed.')
                            ]
                            if (userInput != 'yes') {
                                error("Terraform Apply aborted by user.")
                            }
                        }
                        sh 'echo "yes" | terraform apply'  // Simulate user input
                    }
                }
            }
        }

        stage('Run Ansible Playbook') {
            when {
                expression { return env.ACTION == 'Apply' }
            }
            steps {
                echo "Running Ansible Playbook after applying the changes."
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
                expression { return env.ACTION == 'Destroy' }
            }
            steps {
                echo "You have chosen to destroy the Terraform infrastructure."
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    dir('prometheus-terraform') {
                        script {
                            def userInput = input message: 'Type "yes" to confirm Terraform Destroy:', parameters: [
                                string(name: 'CONFIRM_DESTROY', defaultValue: '', description: 'Only "yes" will proceed.')
                            ]
                            if (userInput != 'yes') {
                                error("Terraform Destroy aborted by user.")
                            }
                        }
                        sh 'echo "yes" | terraform destroy'  // Simulate user input
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
            emailext(
                subject: "Jenkins Pipeline SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """<p>Pipeline <b>${env.JOB_NAME}</b> (Build #${env.BUILD_NUMBER}) completed successfully.</p>
                         <p><a href="${env.BUILD_URL}">Click here to view the build details</a>.</p>""",
                to: 'prince98batra@gmail.com',
                mimeType: 'text/html'
            )
        }
        failure {
            echo ':x: Pipeline failed. Check the logs for details.'
            emailext(
                subject: "Jenkins Pipeline FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """<p>Pipeline <b>${env.JOB_NAME}</b> (Build #${env.BUILD_NUMBER}) failed.</p>
                         <p><a href="${env.BUILD_URL}">Click here to view the build details</a>.</p>""",
                to: 'prince98batra@gmail.com',
                mimeType: 'text/html'
            )
        }
        aborted {
            echo ':no_entry_sign: Pipeline was manually aborted.'
            emailext(
                subject: "Jenkins Pipeline ABORTED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """<p>Pipeline <b>${env.JOB_NAME}</b> (Build #${env.BUILD_NUMBER}) was aborted.</p>
                         <p><a href="${env.BUILD_URL}">Click here to view the build details</a>.</p>""",
                to: 'prince98batra@gmail.com',
                mimeType: 'text/html'
            )
        }
    }
}
