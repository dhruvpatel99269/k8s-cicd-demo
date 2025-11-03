# Quick Start Guide

## TL;DR - Get Running in 5 Minutes

### 1. Update Configuration

Edit `Jenkinsfile` line 5:
```groovy
DOCKERHUB_USERNAME = 'your-dockerhub-username'
```

### 2. Configure Jenkins

1. Install plugins: Pipeline, Docker Pipeline, Kubernetes CLI
2. Add credentials:
   - ID: `dockerhub-credentials`
   - Type: Username with password
   - Your DockerHub username and token

### 3. Create Jenkins Pipeline Job

1. New Item → Pipeline
2. Name: `student-dashboard-cicd`
3. Pipeline from SCM → Git
4. Repository: This repo
5. Script Path: `Jenkinsfile`
6. Save

### 4. Run Pipeline

```bash
# Option 1: Manual trigger
# Click "Build Now" in Jenkins

# Option 2: Push to dev branch
git checkout -b dev
git add .
git commit -m "Setup CI/CD"
git push origin dev

# Option 3: Push to main branch
git checkout main
git push origin main
```

### 5. Verify Deployment

```bash
# Test environment (dev branch)
kubectl get all -n test

# Production environment (main branch)
kubectl get all -n production

# Access application
kubectl port-forward svc/student-dashboard-service-test 8080:80 -n test
# Open http://localhost:8080
```

## Common Commands

```bash
# Check pipeline status
# View in Jenkins UI

# Check deployments
kubectl get deployments -n test
kubectl get deployments -n production

# Check pods
kubectl get pods -n test
kubectl get pods -n production

# View logs
kubectl logs -n test -l app=student-dashboard
kubectl logs -n production -l app=student-dashboard

# Delete and redeploy
kubectl delete -f k8s/deployment-test.yaml
# Trigger pipeline again

# Rollback
kubectl rollout undo deployment/student-dashboard-prod -n production
```

## Branch Strategy

- **dev branch** → Test environment (test namespace)
- **main branch** → Production environment (production namespace)
- Other branches → No deployment

## Image Tags

Images are tagged as: `{branch-name}-{build-number}`
- Example: `dev-42`, `main-15`

## Troubleshooting

**Pipeline fails at Docker build?**
```bash
# Test locally
cd student-dashboard
docker build -t test .
```

**Pipeline fails at Docker push?**
```bash
# Test login
docker login
docker push your-username/student-dashboard:test
```

**Pipeline fails at kubectl?**
```bash
# Test kubectl
kubectl get nodes
kubectl cluster-info
```

**Pods not starting?**
```bash
kubectl describe pod <pod-name> -n test
kubectl get events -n test
```

---

**Need more details? Check README.md for comprehensive guide.**

