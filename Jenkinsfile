pipeline {
    agent any
    triggers {
        pollSCM('H/5 * * * *') // Poll every 5 minutes
    }
    stages {
        stage('Build') {
            steps {
                echo 'Building because changes were detected...'
            }
        }
    }
}
