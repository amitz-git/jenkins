pipeline {
    agent any
    triggers {
        pollSCM('H/15 * * * *') // Poll every 15 minutes
    }
    stages {
        stage('Initialize') {
            steps {
                echo 'Initializing because changes were detected...'
            }
        }
    }
    stages {
        stage('Validate') {
            steps {
                echo 'Validating because changes were detected...'
            }
        }
    }
    stages {
        stage('Plan') {
            steps {
                echo 'Plan because changes were detected...'
            }
        }
    }
    stages {
        stage('Apply') {
            steps {
                echo 'Applying because changes were detected...'
            }
        }
    }
}
