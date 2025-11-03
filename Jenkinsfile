pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub')  // Jenkins credential ID
        DOCKERHUB_USERNAME = 'dhruv99269'
        IMAGE_NAME = 'k8s-cicd-demo'
        IMAGE_TAG = "v${env.BUILD_NUMBER}" // example: v5
    }

    stages {
        stage('Checkout') {
            steps {
                echo "🔹 Checking out source code..."
                checkout scm
                bat 'git log -1 --pretty=oneline'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🔹 Building Docker image..."
                dir('student-dashboard') {
                    bat """
                    docker build -t %DOCKERHUB_USERNAME%/%IMAGE_NAME%:%IMAGE_TAG% .
                    """
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "🔹 Pushing image to Docker Hub..."
                bat """
                docker login -u %DOCKERHUB_USERNAME% -p %DOCKERHUB_CREDENTIALS_PSW%
                docker push %DOCKERHUB_USERNAME%/%IMAGE_NAME%:%IMAGE_TAG%
                docker tag %DOCKERHUB_USERNAME%/%IMAGE_NAME%:%IMAGE_TAG% %DOCKERHUB_USERNAME%/%IMAGE_NAME%:latest
                docker push %DOCKERHUB_USERNAME%/%IMAGE_NAME%:latest
                """
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "🔹 Deploying to Kubernetes..."
                bat """
                kubectl apply -f k8s/deployment.yaml
                """
            }
        }
    }
}
