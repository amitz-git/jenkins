pipeline {
    agent any
    triggers {
        pollSCM('H/15 * * * *') // Poll every 15 minutes
    }
    stages {
        stage('Build') {
            steps {
                echo 'Building because changes were detected...'
            }
        }
    }
}
