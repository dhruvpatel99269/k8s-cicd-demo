# CI/CD Pipeline with Kubernetes and Jenkins - Student Dashboard

This project implements a complete CI/CD pipeline using Jenkins to automatically build, push Docker images to DockerHub, and deploy to Kubernetes clusters.

## Architecture Overview

- **Application**: Student Dashboard (HTML/JavaScript web app)
- **Container**: Docker
- **Registry**: DockerHub
- **Orchestration**: Kubernetes
- **CI/CD**: Jenkins Pipeline
- **Branch Strategy**: 
  - `dev` branch → Test environment (test namespace)
  - `main` branch → Production environment (production namespace)

## Project Structure

```
.
├── student-dashboard/
│   ├── index.html          # Student dashboard web application
│   ├── Dockerfile          # Docker image configuration
│   └── .dockerignore       # Files to exclude from Docker build
├── k8s/
│   ├── deployment.yaml     # Base Kubernetes deployment
│   ├── deployment-test.yaml   # Test environment deployment
│   └── deployment-prod.yaml   # Production environment deployment
├── Jenkinsfile             # Jenkins pipeline definition
└── README.md              # This file
```

## Prerequisites

Before starting, ensure you have the following installed and configured:

1. **Docker**
   - Install Docker Desktop or Docker Engine
   - Verify: `docker --version`

2. **Kubernetes Cluster**
   - Minikube (for local testing) OR
   - GKE, EKS, AKS (for cloud) OR
   - Any Kubernetes cluster with kubectl configured
   - Verify: `kubectl cluster-info`

3. **Jenkins**
   - Jenkins 2.x with Pipeline plugin
   - Docker plugin
   - Kubernetes plugin (if using Kubernetes agent)
   - Verify: Access Jenkins at `http://localhost:8080` (or your Jenkins URL)

4. **Git**
   - Git installed and configured
   - Verify: `git --version`

5. **DockerHub Account**
   - Create account at https://hub.docker.com
   - Note your username for configuration

## Step-by-Step Setup Guide

### Step 1: Prepare Your DockerHub Credentials

1. Log in to DockerHub (https://hub.docker.com)
2. Go to Account Settings → Security
3. Create an access token (or use your password)
4. Save these credentials - you'll need them in Jenkins

### Step 2: Configure Jenkins

#### 2.1 Install Required Plugins

In Jenkins, go to **Manage Jenkins → Manage Plugins** and install:
- Pipeline
- Docker Pipeline
- Kubernetes CLI
- Git

#### 2.2 Configure DockerHub Credentials in Jenkins

1. Go to **Manage Jenkins → Manage Credentials**
2. Click on your domain (usually "Global")
3. Click **Add Credentials**
4. Configure:
   - **Kind**: Username with password
   - **Scope**: Global
   - **Username**: Your DockerHub username
   - **Password**: Your DockerHub access token or password
   - **ID**: `dockerhub-credentials`
   - **Description**: DockerHub credentials
5. Click **OK**

#### 2.3 Configure Kubernetes Credentials (if needed)

If your Jenkins is not running in the Kubernetes cluster:

1. Go to **Manage Jenkins → Manage Credentials**
2. Add credentials with:
   - **Kind**: Secret file
   - **ID**: `kubeconfig-credentials`
   - Upload your `kubeconfig` file

Or if Jenkins is running in-cluster, it will use the service account automatically.

#### 2.4 Update Jenkinsfile with Your DockerHub Username

Edit the `Jenkinsfile` and replace `YOUR_DOCKERHUB_USERNAME` with your actual DockerHub username:

```groovy
DOCKERHUB_USERNAME = 'your-actual-dockerhub-username'
```

### Step 3: Prepare Kubernetes Cluster

#### 3.1 Create Namespaces (if not using the provided manifests)

```bash
kubectl create namespace test
kubectl create namespace production
```

Note: The deployment YAMLs include namespace definitions, so they will be created automatically.

#### 3.2 Verify Cluster Access

```bash
kubectl get nodes
kubectl get namespaces
```

### Step 4: Create Jenkins Pipeline Job

#### 4.1 Create New Pipeline Job

1. In Jenkins, click **New Item**
2. Enter name: `student-dashboard-cicd`
3. Select **Pipeline**
4. Click **OK**

#### 4.2 Configure Pipeline

1. In **Pipeline Definition**, select **Pipeline script from SCM**
2. **SCM**: Git
3. **Repository URL**: Your Git repository URL
   - If local: Use file path or set up Git server
   - If remote: Use HTTPS/SSH URL
4. **Branch Specifier**: `*/dev` or `*/main` (you can configure multiple)
5. **Script Path**: `Jenkinsfile` (keep default)
6. Click **Save**

#### 4.3 Configure GitHub Webhook (Optional but Recommended)

If using GitHub/GitLab:

1. In your repository, go to **Settings → Webhooks**
2. Add webhook:
   - **URL**: `http://your-jenkins-url/github-webhook/`
   - **Content type**: application/json
   - **Events**: Push events
3. Save webhook

### Step 5: Create Git Repository Structure

#### 5.1 Initialize Git Repository

```bash
git init
git add .
git commit -m "Initial commit: Student Dashboard CI/CD setup"
```

#### 5.2 Create Branches

```bash
# Create dev branch
git checkout -b dev
git push origin dev

# Create main branch (if not exists)
git checkout -b main
git push origin main
```

Or if you already have a main branch:

```bash
git checkout main
git merge dev  # Optional: merge dev to main
```

### Step 6: Test the Pipeline

#### 6.1 Trigger Pipeline from Dev Branch

1. In Jenkins, go to your pipeline job
2. Click **Build with Parameters** (if configured) or **Build Now**
3. Or push to dev branch to trigger automatically (if webhook is set up)

#### 6.2 Monitor Pipeline Execution

1. Click on the build number
2. Click **Console Output** to see real-time logs
3. Wait for completion

Expected stages:
- ✅ Checkout
- ✅ Build Docker Image
- ✅ Push to DockerHub
- ✅ Deploy to Kubernetes (test environment)
- ✅ Verification

#### 6.3 Verify Deployment

```bash
# Check test environment
kubectl get deployments -n test
kubectl get pods -n test
kubectl get services -n test

# Get service URL
kubectl get svc student-dashboard-service-test -n test
```

#### 6.4 Test Production Deployment

1. Switch to main branch:
```bash
git checkout main
git merge dev  # or make changes directly
git push origin main
```

2. Pipeline will automatically trigger
3. Deploys to production namespace

```bash
# Check production environment
kubectl get deployments -n production
kubectl get pods -n production
kubectl get services -n production
```

### Step 7: Access the Application

#### 7.1 Get Service Endpoints

For Test Environment:
```bash
kubectl get svc student-dashboard-service-test -n test
# Note the EXTERNAL-IP or use port-forward
kubectl port-forward svc/student-dashboard-service-test 8080:80 -n test
# Access at http://localhost:8080
```

For Production Environment:
```bash
kubectl get svc student-dashboard-service-prod -n production
# Note the EXTERNAL-IP or use port-forward
kubectl port-forward svc/student-dashboard-service-prod 8081:80 -n production
# Access at http://localhost:8081
```

## Pipeline Stages Breakdown

1. **Checkout**: Retrieves source code from Git repository
2. **Build Docker Image**: Creates Docker image from Dockerfile
3. **Push to DockerHub**: Uploads image to DockerHub registry
4. **Deploy to Kubernetes**: 
   - Applies deployment.yaml with environment-specific config
   - Deploys to `test` namespace for `dev` branch
   - Deploys to `production` namespace for `main` branch
5. **Verification**: Checks deployment status and pod health

## Troubleshooting

### Issue: Docker build fails
- **Solution**: Ensure Docker is running and accessible to Jenkins user
  ```bash
  # Add Jenkins user to docker group (Linux)
  sudo usermod -aG docker jenkins
  sudo systemctl restart jenkins
  ```

### Issue: Cannot push to DockerHub
- **Solution**: Verify credentials in Jenkins and test login manually
  ```bash
  docker login
  docker push your-username/student-dashboard:tag
  ```

### Issue: kubectl command not found
- **Solution**: Install kubectl and ensure it's in PATH
  ```bash
  # Install kubectl (Linux)
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  ```

### Issue: Cannot connect to Kubernetes cluster
- **Solution**: Verify kubeconfig is configured correctly
  ```bash
  kubectl config view
  kubectl cluster-info
  ```

### Issue: Pods stuck in Pending state
- **Solution**: Check node resources and taints
  ```bash
  kubectl describe pod <pod-name> -n <namespace>
  kubectl get nodes
  ```

### Issue: Pipeline doesn't trigger on push
- **Solution**: 
  - Verify webhook configuration
  - Check Jenkins logs
  - Manually trigger build to test

## Environment Variables

The pipeline uses these environment variables (configured in Jenkinsfile):

- `DOCKERHUB_USERNAME`: Your DockerHub username
- `DOCKERHUB_REPO`: Repository name (student-dashboard)
- `IMAGE_TAG`: Format: `{branch-name}-{build-number}`
- `BRANCH_NAME`: Current Git branch name

## Best Practices

1. **Security**:
   - Use DockerHub access tokens instead of passwords
   - Store all credentials in Jenkins Credential Manager
   - Use Kubernetes RBAC for cluster access

2. **Image Tagging**:
   - Current: `{branch}-{build-number}`
   - Consider adding: git commit SHA for traceability

3. **Rollback Strategy**:
   ```bash
   # Rollback deployment
   kubectl rollout undo deployment/student-dashboard-prod -n production
   ```

4. **Monitoring**:
   - Set up Kubernetes dashboard
   - Configure Jenkins build notifications
   - Add Slack/Email notifications for build status

## Manual Testing (Optional)

### Test Docker Build Locally

```bash
cd student-dashboard
docker build -t student-dashboard:local .
docker run -p 8080:80 student-dashboard:local
# Access at http://localhost:8080
```

### Test Kubernetes Deployment Locally

```bash
# Update deployment files with your DockerHub username
sed -i 's|DOCKERHUB_USERNAME|your-username|g' k8s/deployment-test.yaml
sed -i 's|IMAGE_TAG|dev-1|g' k8s/deployment-test.yaml

# Apply deployment
kubectl apply -f k8s/deployment-test.yaml

# Check status
kubectl get all -n test
```

## Cleanup

To remove deployments:

```bash
# Remove test environment
kubectl delete -f k8s/deployment-test.yaml

# Remove production environment
kubectl delete -f k8s/deployment-prod.yaml

# Remove namespaces
kubectl delete namespace test
kubectl delete namespace production
```

## Summary

✅ **Complete CI/CD Pipeline Setup**
- Jenkins automatically builds Docker images
- Pushes to DockerHub
- Deploys to Kubernetes based on branch
- Dev branch → Test environment
- Main branch → Production environment

✅ **Automated Deployment**
- Push to branch triggers pipeline
- No manual intervention needed
- Consistent deployment process

✅ **Environment Separation**
- Test and Production isolated in separate namespaces
- Different resource configurations
- Safe for parallel development

## Next Steps

1. Set up monitoring and logging (Prometheus, Grafana)
2. Add automated testing stages
3. Implement blue-green or canary deployments
4. Add security scanning (Trivy, Snyk)
5. Set up notification channels (Slack, Email)

---

**Happy Deploying! 🚀**

