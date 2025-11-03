# Testing Guide - How to Run and Test

This guide walks you through testing each component of the CI/CD pipeline.

## Table of Contents
1. [Local Testing (Without Jenkins)](#local-testing)
2. [Testing with Jenkins Pipeline](#testing-with-jenkins)
3. [Verification Steps](#verification)
4. [Troubleshooting Tests](#troubleshooting)

---

## Local Testing (Without Jenkins)

### Step 1: Test Docker Build Locally

First, verify the Docker image builds correctly:

```bash
# Navigate to the application directory
cd student-dashboard

# Build the Docker image
docker build -t student-dashboard:local .

# You should see output like:
# Step 1/3 : FROM nginx:alpine
# Step 2/3 : COPY index.html /usr/share/nginx/html/
# Step 3/3 : CMD ["nginx", "-g", "daemon off;"]
# Successfully built <image-id>
```

### Step 2: Test Docker Container Locally

Run the container locally to verify the application works:

```bash
# Run the container
docker run -d -p 8080:80 --name student-dashboard-test student-dashboard:local

# Check if container is running
docker ps

# Test the application
# Open browser: http://localhost:8080
# Or use curl:
curl http://localhost:8080

# Stop and remove container
docker stop student-dashboard-test
docker rm student-dashboard-test
```

### Step 3: Test Docker Push to DockerHub

Verify you can push images to DockerHub:

```bash
# Login to DockerHub
docker login
# Enter your DockerHub username and password/token

# Tag the image with your DockerHub username
docker tag student-dashboard:local YOUR_DOCKERHUB_USERNAME/student-dashboard:test

# Push to DockerHub
docker push YOUR_DOCKERHUB_USERNAME/student-dashboard:test

# Verify on DockerHub website
# Visit: https://hub.docker.com/r/YOUR_DOCKERHUB_USERNAME/student-dashboard
```

### Step 4: Test Kubernetes Deployment Locally

If you have a local Kubernetes cluster (Minikube, Docker Desktop, etc.):

```bash
# Make sure kubectl is configured
kubectl cluster-info

# Create test namespace (if not exists)
kubectl create namespace test

# Update the deployment file with your DockerHub username
cd ..
# On Linux/Mac:
sed -i 's|DOCKERHUB_USERNAME|YOUR_DOCKERHUB_USERNAME|g' k8s/deployment-test.yaml
sed -i 's|IMAGE_TAG|test|g' k8s/deployment-test.yaml

# On Windows PowerShell:
(Get-Content k8s/deployment-test.yaml) -replace 'DOCKERHUB_USERNAME', 'YOUR_DOCKERHUB_USERNAME' | Set-Content k8s/deployment-test.yaml
(Get-Content k8s/deployment-test.yaml) -replace 'IMAGE_TAG', 'test' | Set-Content k8s/deployment-test.yaml

# Apply the deployment
kubectl apply -f k8s/deployment-test.yaml

# Check deployment status
kubectl get deployments -n test
kubectl get pods -n test
kubectl get services -n test

# Wait for pod to be ready
kubectl wait --for=condition=ready pod -l app=student-dashboard -n test --timeout=60s

# Access the application
# Option 1: Port forward
kubectl port-forward svc/student-dashboard-service-test 8080:80 -n test
# Then open http://localhost:8080

# Option 2: Get LoadBalancer IP (if using cloud provider)
kubectl get svc student-dashboard-service-test -n test

# Check logs
kubectl logs -n test -l app=student-dashboard

# Clean up
kubectl delete -f k8s/deployment-test.yaml
```

---

## Testing with Jenkins Pipeline

### Prerequisites Check

Before testing the Jenkins pipeline, verify:

```bash
# 1. Jenkins is running
# Check: http://localhost:8080 (or your Jenkins URL)

# 2. Docker is accessible
docker --version
docker ps

# 3. kubectl is accessible
kubectl version --client
kubectl get nodes

# 4. Git repository is set up
git status
git remote -v
```

### Step 1: Prepare Jenkins

#### A. Install Required Plugins

1. Go to Jenkins: **Manage Jenkins → Manage Plugins**
2. Install:
   - ✅ Pipeline
   - ✅ Docker Pipeline
   - ✅ Kubernetes CLI
   - ✅ Git

#### B. Configure DockerHub Credentials

1. Go to: **Manage Jenkins → Manage Credentials**
2. Click: **Add Credentials**
3. Fill in:
   - **Kind**: Username with password
   - **Scope**: Global
   - **Username**: Your DockerHub username
   - **Password**: Your DockerHub access token (or password)
   - **ID**: `dockerhub-credentials` ⚠️ **MUST be exact**
   - **Description**: DockerHub credentials
4. Click **OK**

#### C. Update Jenkinsfile

Edit `Jenkinsfile` line 6:
```groovy
DOCKERHUB_USERNAME = 'your-actual-dockerhub-username'
```

Replace `your-actual-dockerhub-username` with your real DockerHub username.

#### D. Create Pipeline Job

1. Click **New Item**
2. Name: `student-dashboard-cicd`
3. Select **Pipeline**
4. Click **OK**

#### E. Configure Pipeline

1. Scroll to **Pipeline** section
2. **Definition**: Pipeline script from SCM
3. **SCM**: Git
4. **Repository URL**: 
   - Local: `/path/to/repo` or `file:///path/to/repo`
   - Remote: `https://github.com/yourusername/repo.git` or `git@github.com:yourusername/repo.git`
5. **Credentials**: Add if using private repo
6. **Branch Specifier**: `*/dev` (for dev branch) or `*/main` (for main)
   - Or use `**` for all branches
7. **Script Path**: `Jenkinsfile`
8. Click **Save**

### Step 2: Test with Dev Branch

#### A. Create and Push Dev Branch

```bash
# Make sure you're in the project root
cd /path/to/devopslabexam

# Create dev branch
git checkout -b dev

# Commit all files
git add .
git commit -m "Setup CI/CD pipeline"

# Push to remote (if using remote repo)
git push origin dev

# Or if Jenkins uses local repo, ensure files are committed
git status
```

#### B. Trigger Pipeline in Jenkins

**Option 1: Manual Trigger**
1. Go to Jenkins pipeline job
2. Click **Build Now**
3. Watch the build progress

**Option 2: Automatic Trigger (if webhook configured)**
- Just push to dev branch
- Pipeline will trigger automatically

#### C. Monitor Build

1. Click on the build number (e.g., #1)
2. Click **Console Output**
3. Watch for:
   ```
   [Pipeline] stage
   [Pipeline] { (Checkout)
   [Pipeline] stage
   [Pipeline] { (Build Docker Image)
   [Pipeline] stage
   [Pipeline] { (Push to DockerHub)
   [Pipeline] stage
   [Pipeline] { (Deploy to Kubernetes)
   [Pipeline] stage
   [Pipeline] { (Verification)
   ```

#### D. Verify Test Deployment

```bash
# Check test namespace
kubectl get all -n test

# Expected output:
# deployment.apps/student-dashboard-test   1/1     1            1          2m
# pod/student-dashboard-test-xxxxxxxxxx    1/1     Running      0          2m
# service/student-dashboard-service-test   LoadBalancer   10.x.x.x   <pending>   80:xxxxx/TCP   2m

# Check pod details
kubectl describe pod -n test -l app=student-dashboard

# Check logs
kubectl logs -n test -l app=student-dashboard

# Access application
kubectl port-forward svc/student-dashboard-service-test 8080:80 -n test
# Open http://localhost:8080 in browser
```

### Step 3: Test with Main Branch (Production)

#### A. Switch to Main Branch

```bash
# Switch to main branch
git checkout main

# Merge dev (or make changes)
git merge dev

# Push to remote
git push origin main
```

#### B. Trigger Production Pipeline

Same as dev branch - Jenkins will automatically detect main branch and deploy to production.

#### C. Verify Production Deployment

```bash
# Check production namespace
kubectl get all -n production

# Expected: 3 replicas
# deployment.apps/student-dashboard-prod   3/3     3            3          2m
# pod/student-dashboard-prod-xxxxxxxxxx    1/1     Running      0          2m
# pod/student-dashboard-prod-xxxxxxxxxx    1/1     Running      0          2m
# pod/student-dashboard-prod-xxxxxxxxxx    1/1     Running      0          2m

# Access production
kubectl port-forward svc/student-dashboard-service-prod 8081:80 -n production
# Open http://localhost:8081 in browser
```

---

## Verification

### Complete Test Checklist

Run through this checklist to verify everything works:

#### ✅ Local Docker Test
- [ ] Docker image builds successfully
- [ ] Container runs without errors
- [ ] Application accessible at http://localhost:8080
- [ ] Application displays correctly

#### ✅ DockerHub Test
- [ ] Docker login successful
- [ ] Image pushes to DockerHub
- [ ] Image visible on DockerHub website
- [ ] Image can be pulled: `docker pull username/student-dashboard:test`

#### ✅ Kubernetes Test
- [ ] Deployment creates successfully
- [ ] Pods start and become Ready
- [ ] Service is created
- [ ] Application accessible via port-forward
- [ ] Application accessible via LoadBalancer (if configured)

#### ✅ Jenkins Pipeline Test
- [ ] Pipeline job created
- [ ] Credentials configured
- [ ] Pipeline triggers on push
- [ ] All stages complete successfully:
  - [ ] Checkout ✅
  - [ ] Build Docker Image ✅
  - [ ] Push to DockerHub ✅
  - [ ] Deploy to Kubernetes ✅
  - [ ] Verification ✅
- [ ] Test deployment works (dev branch)
- [ ] Production deployment works (main branch)

#### ✅ Application Functionality Test
- [ ] Student cards display correctly
- [ ] Environment banner shows correct environment
- [ ] Page is responsive
- [ ] No console errors in browser

---

## Troubleshooting Tests

### Issue: Docker build fails

```bash
# Check Docker is running
docker ps

# Check Dockerfile syntax
cd student-dashboard
cat Dockerfile

# Try building with verbose output
docker build --no-cache -t test .
```

### Issue: Cannot push to DockerHub

```bash
# Test login
docker login

# Check credentials
docker logout
docker login

# Verify image tag format
docker images | grep student-dashboard

# Tag correctly
docker tag student-dashboard:local YOUR_USERNAME/student-dashboard:test

# Try push
docker push YOUR_USERNAME/student-dashboard:test
```

### Issue: Jenkins pipeline fails at Docker build

```bash
# Check if Jenkins user can access Docker
# On Linux, add Jenkins user to docker group:
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# Check Jenkins workspace
# In Jenkins: Build → Workspace → student-dashboard
# Verify Dockerfile exists

# Check Jenkins logs
# Linux: /var/log/jenkins/jenkins.log
# Or: Manage Jenkins → System Log
```

### Issue: kubectl command not found in Jenkins

```bash
# Install kubectl in Jenkins server
# Linux:
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify in Jenkins:
# Go to: Manage Jenkins → Script Console
# Run: sh 'kubectl version --client'
```

### Issue: Pods stuck in Pending state

```bash
# Check why pod is pending
kubectl describe pod -n test -l app=student-dashboard

# Common issues:
# - Insufficient resources
# - Image pull errors
# - Node taints

# Check events
kubectl get events -n test --sort-by='.lastTimestamp'

# Check node resources
kubectl top nodes
kubectl describe nodes
```

### Issue: Image pull errors in Kubernetes

```bash
# Check if image exists on DockerHub
# Visit: https://hub.docker.com/r/YOUR_USERNAME/student-dashboard

# Verify image name in deployment
kubectl get deployment -n test -o yaml | grep image:

# Check pod events
kubectl describe pod -n test -l app=student-dashboard | grep -A 10 Events

# Test pulling image manually
docker pull YOUR_USERNAME/student-dashboard:dev-1
```

### Issue: Pipeline doesn't trigger automatically

```bash
# Check webhook configuration (if using GitHub/GitLab)
# GitHub: Settings → Webhooks → Check webhook URL and events

# Check Jenkins logs for webhook errors
# Manage Jenkins → System Log

# Test webhook manually
# In GitHub: Webhooks → Recent Deliveries → Redeliver

# Or use manual trigger
# Jenkins → Pipeline → Build Now
```

### Issue: Deployment YAML not found

```bash
# Verify file exists in repository
ls -la k8s/deployment-test.yaml

# Check Jenkins workspace
# In Jenkins: Build → Workspace
# Verify: k8s/deployment-test.yaml exists

# Check git repository
git ls-files k8s/
```

---

## Quick Test Commands

Copy-paste these commands for quick testing:

```bash
# 1. Local Docker test
cd student-dashboard && docker build -t test . && docker run -p 8080:80 test

# 2. Test DockerHub push
docker tag test YOUR_USERNAME/student-dashboard:test && docker push YOUR_USERNAME/student-dashboard:test

# 3. Test Kubernetes deployment
kubectl apply -f k8s/deployment-test.yaml && kubectl get all -n test

# 4. Check pod status
kubectl get pods -n test -w

# 5. View logs
kubectl logs -n test -l app=student-dashboard --tail=50

# 6. Port forward and test
kubectl port-forward svc/student-dashboard-service-test 8080:80 -n test &
curl http://localhost:8080

# 7. Cleanup
kubectl delete -f k8s/deployment-test.yaml
docker stop $(docker ps -q --filter ancestor=test) && docker rm $(docker ps -aq --filter ancestor=test)
```

---

## Success Criteria

Your pipeline is working correctly if:

✅ Docker image builds locally  
✅ Image pushes to DockerHub  
✅ Jenkins pipeline completes all stages  
✅ Kubernetes pods are Running  
✅ Application is accessible  
✅ Dev branch deploys to test namespace  
✅ Main branch deploys to production namespace  
✅ Environment banner shows correct environment  

---

**Need help? Check the main README.md for detailed setup instructions!**

