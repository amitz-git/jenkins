pipeline {
    agent any
    triggers {
        pollSCM('H/15 * * * *') // Poll every 15 minutes
    }
    stages {
        stage('Initialize') {
            steps {
                sh 'terraform init'
            }
        }
        stage('Validate') {
            steps {
                sh 'terraform validate'
            }
        }
        stage('Plan') {
            steps {
                sh 'terraform plan'
            }
        }
        stage('Apply') {
            steps {
                sh 'terraform apply'
            }
        }
    }
}
