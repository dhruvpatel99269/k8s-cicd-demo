pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKERHUB_USERNAME = "dhruv99269"
        IMAGE_NAME = "k8s-cicd-demo"
        IMAGE_TAG = "${BUILD_NUMBER}"
        FULL_IMAGE = "${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
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
                dir('student-dashboard') { // remove this if Dockerfile is in root
                    bat """
                    docker build -t ${FULL_IMAGE} .
                    """
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "🔹 Pushing image to Docker Hub..."
                bat """
                docker login -u ${DOCKERHUB_CREDENTIALS_USR} -p ${DOCKERHUB_CREDENTIALS_PSW}
                docker push ${FULL_IMAGE}
                docker tag ${FULL_IMAGE} ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest
                docker push ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest
                """
            }
        }
    }
}
