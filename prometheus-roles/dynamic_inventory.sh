pipeline {
    agent any

    stages {
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve'
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                sh 'ansible-playbook -i dynamic_inventory.sh playbook.yml'
            }
        }
    }

    post {
        always {
            script {
                def userInput = input(
                    id: 'Proceed', message: 'Do you want to destroy the infrastructure?', ok: 'Destroy'
                )
                if (userInput) {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
    }
}
