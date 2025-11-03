pipeline {
    agent any
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKERHUB_USERNAME = "dhruv99269"
        DOCKERHUB_REPO = 'k8s-cicd-demo'
        IMAGE_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
        KUBECONFIG_CREDENTIALS = credentials('kubeconfig-credentials')
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
                sh 'git branch'
                sh 'git log -1'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
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
                echo 'Pushing image to DockerHub...'
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                        docker push ${DOCKERHUB_USERNAME}/${DOCKERHUB_REPO}:${IMAGE_TAG}
                        docker push ${DOCKERHUB_USERNAME}/${DOCKERHUB_REPO}:latest
                    """
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'dev') {
                        echo 'Deploying to TEST environment...'
                        def deploymentFile = 'k8s/deployment-test.yaml'
                        sh """
                            sed -i 's|DOCKERHUB_USERNAME|${DOCKERHUB_USERNAME}|g' ${deploymentFile}
                            sed -i 's|IMAGE_TAG|${IMAGE_TAG}|g' ${deploymentFile}
                            kubectl apply -f ${deploymentFile}
                            kubectl rollout status deployment/student-dashboard-test -n test --timeout=300s
                        """
                    } else if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master') {
                        echo 'Deploying to PRODUCTION environment...'
                        def deploymentFile = 'k8s/deployment-prod.yaml'
                        sh """
                            sed -i 's|DOCKERHUB_USERNAME|${DOCKERHUB_USERNAME}|g' ${deploymentFile}
                            sed -i 's|IMAGE_TAG|${IMAGE_TAG}|g' ${deploymentFile}
                            kubectl apply -f ${deploymentFile}
                            kubectl rollout status deployment/student-dashboard-prod -n production --timeout=300s
                        """
                    } else {
                        echo "Branch ${env.BRANCH_NAME} does not trigger deployment"
                    }
                }
            }
        }
        
        stage('Verification') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'dev') {
                        sh """
                            kubectl get deployments -n test
                            kubectl get pods -n test
                            kubectl get services -n test
                        """
                    } else if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master') {
                        sh """
                            kubectl get deployments -n production
                            kubectl get pods -n production
                            kubectl get services -n production
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
            script {
                if (env.BRANCH_NAME == 'dev') {
                    echo "Deployed to TEST environment. Image: ${DOCKERHUB_USERNAME}/${DOCKERHUB_REPO}:${IMAGE_TAG}"
                } else if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master') {
                    echo "Deployed to PRODUCTION environment. Image: ${DOCKERHUB_USERNAME}/${DOCKERHUB_REPO}:${IMAGE_TAG}"
                }
            }
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            cleanWs()
        }
    }
}

