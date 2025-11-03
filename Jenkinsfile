pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKERHUB_USERNAME = "dhruv99269"
        DOCKERHUB_REPO = "k8s-cicd-demo"
        IMAGE_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo '🔹 Checking out source code...'
                checkout scm
                sh 'git log -1 --pretty=oneline'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🔹 Building Docker image...'
                dir('student-dashboard') {
                    sh """
                        docker build -t ${DOCKERHUB_USERNAME}/${DOCKERHUB_REPO}:${IMAGE_TAG} .
                        docker tag ${DOCKERHUB_USERNAME}/${DOCKERHUB_REPO}:${IMAGE_TAG} ${DOCKERHUB_USERNAME}/${DOCKERHUB_REPO}:latest
                    """
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                echo '🔹 Pushing image to DockerHub...'
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                        docker push ${DOCKERHUB_USERNAME}/${DOCKERHUB_REPO}:${IMAGE_TAG}
                        docker push ${DOCKERHUB_USERNAME}/${DOCKERHUB_REPO}:latest
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Successfully built and pushed image: ${DOCKERHUB_USERNAME}/${DOCKERHUB_REPO}:${IMAGE_TAG}"
        }
        failure {
            echo '❌ Pipeline failed!'
        }
        always {
            echo '🧹 Cleaning workspace...'
            cleanWs()
        }
    }
}
