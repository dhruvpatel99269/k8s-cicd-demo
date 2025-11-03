# How to Test Everything - Complete Guide

This guide will walk you through testing your entire CI/CD pipeline step by step.

## Prerequisites Checklist

Before testing, make sure you have:

- [ ] Docker installed and running
- [ ] Kubernetes cluster accessible (kubectl configured)
- [ ] Jenkins installed and running
- [ ] DockerHub account (username: `dhruv99269`)
- [ ] Git repository set up

---

## Step 1: Test Docker Build Locally ✅

### Test the Application Build

```bash
# Navigate to application directory
cd student-dashboard

# Build the Docker image
docker build -t dhruv99269/k8s-cicd-demo:local .

# Expected output:
# Successfully built <image-id>
# Successfully tagged dhruv99269/k8s-cicd-demo:local
```

### Test Running the Container

```bash
# Run the container
docker run -d -p 8081:80 --name test-app dhruv99269/k8s-cicd-demo:local

# Check if container is running
docker ps

# Test the application
# Open browser: http://localhost:8080
# OR use curl:
curl http://localhost:8080

# You should see the Student Dashboard page with student cards

# Clean up
docker stop test-app
docker rm test-app
```

**✅ Success if:** Image builds, container runs, and you can see the dashboard at http://localhost:8080

---

## Step 2: Test DockerHub Push ✅

### Login to DockerHub

```bash
# Login with your DockerHub credentials
docker login

# Enter username: dhruv99269
# Enter password/access token
```

### Push Image to DockerHub

```bash
# Tag the image (if not already tagged)
docker tag dhruv99269/k8s-cicd-demo:local dhruv99269/k8s-cicd-demo:test

# Push to DockerHub
docker push dhruv99269/k8s-cicd-demo:test

# Expected output:
# The push refers to repository [docker.io/dhruv99269/k8s-cicd-demo]
# latest: digest: sha256:... size: ...
```

### Verify on DockerHub

1. Go to: https://hub.docker.com/r/dhruv99269/k8s-cicd-demo
2. You should see your `test` tag

**✅ Success if:** Image pushes successfully and appears on DockerHub

---

## Step 3: Test Kubernetes Deployment Manually ✅

### Prepare Deployment Files

First, update the deployment files with your DockerHub username and image tag:

**On Windows (PowerShell):**
```powershell
# Update test deployment
$content = Get-Content k8s\deployment-test.yaml -Raw
$content = $content -replace 'DOCKERHUB_USERNAME', 'dhruv99269'
$content = $content -replace 'IMAGE_TAG', 'test'
Set-Content k8s\deployment-test-manual.yaml -Value $content

# Update production deployment
$content = Get-Content k8s\deployment-prod.yaml -Raw
$content = $content -replace 'DOCKERHUB_USERNAME', 'dhruv99269'
$content = $content -replace 'IMAGE_TAG', 'test'
Set-Content k8s\deployment-prod-manual.yaml -Value $content
```

**On Linux/Mac:**
```bash
# Update test deployment
sed 's|DOCKERHUB_USERNAME|dhruv99269|g' k8s/deployment-test.yaml | \
sed 's|IMAGE_TAG|test|g' > k8s/deployment-test-manual.yaml

# Update production deployment
sed 's|DOCKERHUB_USERNAME|dhruv99269|g' k8s/deployment-prod.yaml | \
sed 's|IMAGE_TAG|test|g' > k8s/deployment-prod-manual.yaml
```

### Deploy to Test Environment

```bash
# Apply test deployment
kubectl apply -f k8s/deployment-test-manual.yaml

# Check deployment status
kubectl get deployments -n test
kubectl get pods -n test
kubectl get services -n test

# Wait for pods to be ready (should show 1/1 Running)
kubectl wait --for=condition=ready pod -l app=student-dashboard -n test --timeout=60s

# Check pod logs
kubectl logs -n test -l app=student-dashboard
```

### Access the Application

**Option 1: Port Forward**
```bash
# Forward port 8080 to service
kubectl port-forward svc/student-dashboard-service-test 8080:80 -n test

# Open browser: http://localhost:8080
# Press Ctrl+C to stop port forwarding
```

**Option 2: LoadBalancer (if available)**
```bash
# Get the external IP
kubectl get svc student-dashboard-service-test -n test

# Access using the EXTERNAL-IP
```

**✅ Success if:** Pods are running, service is created, and you can access the dashboard

### Clean Up Test Deployment

```bash
kubectl delete -f k8s/deployment-test-manual.yaml
```

---

## Step 4: Configure Jenkins ✅

### Install Required Plugins

1. Go to Jenkins: **Manage Jenkins → Manage Plugins**
2. Install these plugins:
   - ✅ Pipeline
   - ✅ Docker Pipeline
   - ✅ Kubernetes CLI
   - ✅ Git

### Configure DockerHub Credentials

1. Go to: **Manage Jenkins → Manage Credentials**
2. Click: **Add Credentials**
3. Configure:
   - **Kind**: Username with password
   - **Scope**: Global
   - **Username**: `dhruv99269`
   - **Password**: Your DockerHub access token (or password)
   - **ID**: `dockerhub-credentials` ⚠️ **MUST be exact**
   - **Description**: DockerHub credentials
4. Click **OK**

### Create Pipeline Job

1. Click **New Item**
2. Name: `student-dashboard-cicd`
3. Select **Pipeline**
4. Click **OK**

### Configure Pipeline Job

1. Scroll to **Pipeline** section
2. **Definition**: Pipeline script from SCM
3. **SCM**: Git
4. **Repository URL**: 
   - If using local Git: `/path/to/devopslabexam` or `file:///E:/devopslabexam`
   - If using remote: Your Git repository URL
5. **Branch Specifier**: 
   - For dev: `*/dev`
   - For main: `*/main`
   - Or use `**` for all branches
6. **Script Path**: `Jenkinsfile`
7. Click **Save**

**✅ Success if:** Pipeline job is created and Jenkinsfile is visible

---

## Step 5: Test Jenkins Pipeline with Dev Branch ✅

### Prepare Dev Branch

```bash
# Make sure you're in the project root
cd /path/to/devopslabexam

# Create dev branch (if not exists)
git checkout -b dev

# Verify Jenkinsfile has correct settings
# DOCKERHUB_USERNAME = "dhruv99269"
# DOCKERHUB_REPO = 'k8s-cicd-demo'

# Commit all files
git add .
git commit -m "Setup CI/CD pipeline for testing"

# Push to remote (if using remote repo)
git push origin dev

# OR if using local repo, make sure files are committed
git status
```

### Trigger Pipeline

**Option 1: Manual Trigger**
1. Go to Jenkins pipeline job
2. Click **Build Now**
3. Click on the build number (#1)
4. Click **Console Output** to watch progress

**Option 2: Automatic Trigger (if webhook configured)**
- Push to dev branch will automatically trigger

### Monitor Pipeline Execution

Watch for these stages:

```
[Pipeline] stage
[Pipeline] { (Checkout)
  ✓ Checking out source code...

[Pipeline] stage
[Pipeline] { (Build Docker Image)
  ✓ Building Docker image...
  ✓ docker build -t dhruv99269/k8s-cicd-demo:dev-1 .

[Pipeline] stage
[Pipeline] { (Push to DockerHub)
  ✓ Pushing image to DockerHub...
  ✓ docker push dhruv99269/k8s-cicd-demo:dev-1

[Pipeline] stage
[Pipeline] { (Deploy to Kubernetes)
  ✓ Deploying to TEST environment...
  ✓ kubectl apply -f k8s/deployment-test.yaml

[Pipeline] stage
[Pipeline] { (Verification)
  ✓ kubectl get deployments -n test
```

### Verify Deployment

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

**✅ Success if:** 
- All pipeline stages complete successfully
- Image appears on DockerHub as `dhruv99269/k8s-cicd-demo:dev-1`
- Pods are running in test namespace
- Application is accessible

---

## Step 6: Test Jenkins Pipeline with Main Branch (Production) ✅

### Switch to Main Branch

```bash
# Switch to main branch
git checkout main

# Merge dev or make changes
git merge dev

# Push to remote (if using remote repo)
git push origin main
```

### Monitor Production Pipeline

1. Pipeline will automatically trigger (if webhook configured)
2. OR manually trigger: **Build Now**
3. Watch Console Output

### Verify Production Deployment

```bash
# Check production namespace
kubectl get all -n production

# Expected: 3 replicas (production has more resources)
# deployment.apps/student-dashboard-prod   3/3     3            3          2m
# pod/student-dashboard-prod-xxx-1         1/1     Running      0          2m
# pod/student-dashboard-prod-xxx-2         1/1     Running      0          2m
# pod/student-dashboard-prod-xxx-3         1/1     Running      0          2m

# Access production
kubectl port-forward svc/student-dashboard-service-prod 8081:80 -n production
# Open http://localhost:8081 in browser
```

**✅ Success if:**
- Pipeline deploys to production namespace
- 3 replicas are running (production has more pods)
- Application is accessible

---

## Step 7: Test Different Scenarios ✅

### Test 1: Image Update

Make a change to the application:

```bash
# Edit student-dashboard/index.html
# Change something (e.g., add a new student card)

# Commit and push
git add student-dashboard/index.html
git commit -m "Update application"
git push origin dev

# Watch pipeline rebuild and redeploy
# New image: dhruv99269/k8s-cicd-demo:dev-2
```

**✅ Success if:** New image is built, pushed, and deployment updates

### Test 2: Rollback

```bash
# Rollback deployment
kubectl rollout undo deployment/student-dashboard-prod -n production

# Check status
kubectl rollout history deployment/student-dashboard-prod -n production
```

### Test 3: Scale Deployment

```bash
# Scale test deployment
kubectl scale deployment student-dashboard-test --replicas=2 -n test

# Check pods
kubectl get pods -n test
```

---

## Complete Test Checklist ✅

Run through this checklist to verify everything works:

### Local Testing
- [ ] Docker image builds successfully
- [ ] Container runs locally
- [ ] Application accessible at http://localhost:8080
- [ ] Docker push to DockerHub works
- [ ] Image visible on DockerHub

### Kubernetes Testing
- [ ] Manual deployment to test namespace works
- [ ] Pods start and become Ready
- [ ] Service is created
- [ ] Application accessible via port-forward
- [ ] Logs are visible

### Jenkins Pipeline Testing
- [ ] Jenkins plugins installed
- [ ] DockerHub credentials configured
- [ ] Pipeline job created
- [ ] Dev branch pipeline completes successfully
- [ ] Main branch pipeline completes successfully
- [ ] Images pushed to DockerHub with correct tags
- [ ] Deployments created in correct namespaces

### Application Testing
- [ ] Test environment shows correct environment banner
- [ ] Production environment shows correct environment banner
- [ ] Student cards display correctly
- [ ] Page is responsive

---

## Quick Test Commands Reference

```bash
# 1. Test Docker locally
cd student-dashboard && docker build -t dhruv99269/k8s-cicd-demo:local . && docker run -p 8080:80 dhruv99269/k8s-cicd-demo:local

# 2. Test DockerHub push
docker login && docker push dhruv99269/k8s-cicd-demo:test

# 3. Test Kubernetes
kubectl apply -f k8s/deployment-test-manual.yaml && kubectl get all -n test

# 4. Check pipeline status
# In Jenkins: View Console Output

# 5. Verify deployments
kubectl get all -n test
kubectl get all -n production

# 6. View logs
kubectl logs -n test -l app=student-dashboard
kubectl logs -n production -l app=student-dashboard

# 7. Access applications
kubectl port-forward svc/student-dashboard-service-test 8080:80 -n test &
kubectl port-forward svc/student-dashboard-service-prod 8081:80 -n production &

# 8. Cleanup
kubectl delete -f k8s/deployment-test-manual.yaml
kubectl delete -f k8s/deployment-prod-manual.yaml
```

---

## Troubleshooting Common Issues

### Issue: Docker build fails in Jenkins
```bash
# Check Docker is accessible to Jenkins user
# Linux: sudo usermod -aG docker jenkins && sudo systemctl restart jenkins
# Check Jenkins workspace has Dockerfile
```

### Issue: Cannot push to DockerHub
```bash
# Verify credentials in Jenkins
# Test manually: docker login
# Check image tag format: dhruv99269/k8s-cicd-demo:tag
```

### Issue: kubectl not found in Jenkins
```bash
# Install kubectl on Jenkins server
# Add to PATH or use full path in Jenkinsfile
```

### Issue: Pods stuck in Pending
```bash
# Check node resources
kubectl describe pod -n test -l app=student-dashboard
kubectl get events -n test
```

### Issue: Image pull errors
```bash
# Verify image exists: https://hub.docker.com/r/dhruv99269/k8s-cicd-demo
# Check image name in deployment YAML
# Test pulling manually: docker pull dhruv99269/k8s-cicd-demo:dev-1
```

---

## Success Criteria ✅

Your CI/CD pipeline is working correctly if:

✅ Docker images build locally and in Jenkins  
✅ Images push to DockerHub successfully  
✅ Jenkins pipeline completes all stages  
✅ Kubernetes pods are Running  
✅ Application is accessible  
✅ Dev branch → Test namespace  
✅ Main branch → Production namespace  
✅ New changes trigger automatic rebuild and redeploy  

---

**You're all set! Follow these steps in order to test everything. Start with Step 1 and work your way through. Good luck! 🚀**

