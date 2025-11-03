# Project Overview - CI/CD Pipeline with Kubernetes and Jenkins

## Project Structure

```
devopslabexam/
│
├── student-dashboard/          # Application source code
│   ├── index.html              # Student Dashboard web application
│   ├── Dockerfile              # Docker image definition
│   └── .dockerignore           # Files excluded from Docker build
│
├── k8s/                         # Kubernetes manifests
│   ├── deployment.yaml         # Base deployment template
│   ├── deployment-test.yaml    # Test environment deployment
│   └── deployment-prod.yaml    # Production environment deployment
│
├── Jenkinsfile                  # Jenkins Pipeline definition
│
├── README.md                    # Comprehensive setup guide
├── QUICK_START.md              # Quick reference guide
├── SETUP_CHECKLIST.md          # Setup verification checklist
└── PROJECT_OVERVIEW.md         # This file

```

## What Each File Does

### Application Files

**`student-dashboard/index.html`**
- Simple, responsive web application
- Displays student information in cards
- Shows environment banner (Test/Production)
- No backend required - pure HTML/CSS/JavaScript

**`student-dashboard/Dockerfile`**
- Uses nginx:alpine as base image
- Copies HTML files to nginx web root
- Exposes port 80
- Lightweight production-ready image

**`student-dashboard/.dockerignore`**
- Prevents unnecessary files from being copied to Docker image
- Reduces image size and build time

### Kubernetes Files

**`k8s/deployment-test.yaml`**
- Kubernetes Deployment for test environment
- Creates `test` namespace
- 1 replica for testing
- LoadBalancer service
- Environment variables set to "test"
- Placeholders: `DOCKERHUB_USERNAME` and `IMAGE_TAG` (replaced by Jenkins)

**`k8s/deployment-prod.yaml`**
- Kubernetes Deployment for production environment
- Creates `production` namespace
- 3 replicas for high availability
- LoadBalancer service
- Environment variables set to "production"
- Higher resource limits than test
- Placeholders: `DOCKERHUB_USERNAME` and `IMAGE_TAG` (replaced by Jenkins)

**`k8s/deployment.yaml`**
- Generic deployment template
- Can be used as reference or for custom deployments

### CI/CD Files

**`Jenkinsfile`**
- Declarative Jenkins Pipeline
- Stages:
  1. **Checkout**: Get source code from Git
  2. **Build**: Create Docker image
  3. **Push**: Upload to DockerHub
  4. **Deploy**: Apply Kubernetes manifests
  5. **Verify**: Check deployment status
- Branch-based deployment:
  - `dev` → test namespace
  - `main` → production namespace
- Replaces placeholders in YAML files with actual values

### Documentation Files

**`README.md`**
- Complete step-by-step setup guide
- Prerequisites and installation
- Configuration instructions
- Troubleshooting section
- Best practices

**`QUICK_START.md`**
- TL;DR guide for experienced users
- Quick commands reference
- Common troubleshooting commands

**`SETUP_CHECKLIST.md`**
- Checklist format for setup verification
- Ensures all components configured correctly
- Troubleshooting checklist included

## Pipeline Flow

```
┌─────────────┐
│ Git Push    │
│ (dev/main)  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Jenkins    │
│  Triggered  │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│ 1. Checkout Code     │
│    - Get from Git    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 2. Build Docker Image│
│    - docker build    │
│    - Tag image       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 3. Push to DockerHub │
│    - docker login    │
│    - docker push     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 4. Deploy to K8s    │
│    - Update YAML    │
│    - kubectl apply  │
│    - Wait for ready │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 5. Verification      │
│    - Check pods      │
│    - Check services  │
└─────────────────────┘
```

## Branch Strategy

```
dev branch  ────────►  test namespace     (1 replica, lower resources)
                                    │
                                    ▼
main branch ────────►  production namespace (3 replicas, higher resources)
```

## Key Features

✅ **Automated Build**: Docker image built automatically on every push
✅ **Automated Push**: Images pushed to DockerHub registry
✅ **Automated Deploy**: Kubernetes deployments updated automatically
✅ **Environment Separation**: Test and Production isolated
✅ **Branch-based**: Different branches deploy to different environments
✅ **Rolling Updates**: Kubernetes handles zero-downtime updates
✅ **Health Checks**: Liveness and readiness probes configured
✅ **Resource Management**: CPU and memory limits set

## Technology Stack

- **Application**: HTML, CSS, JavaScript (static web app)
- **Web Server**: nginx (Alpine Linux)
- **Container**: Docker
- **Registry**: DockerHub
- **Orchestration**: Kubernetes
- **CI/CD**: Jenkins Pipeline

## Environment Variables

Configured in `Jenkinsfile`:
- `DOCKERHUB_USERNAME`: Your DockerHub username (REQUIRED: Update this!)
- `DOCKERHUB_REPO`: Repository name (student-dashboard)
- `IMAGE_TAG`: Auto-generated (`{branch}-{build-number}`)
- `BRANCH_NAME`: Git branch name (auto-detected)

## Image Naming Convention

Images are tagged as: `{username}/student-dashboard:{branch}-{build-number}`

Examples:
- `myuser/student-dashboard:dev-42`
- `myuser/student-dashboard:main-15`
- `myuser/student-dashboard:latest` (points to most recent)

## Deployment Namespaces

- **test**: Development/testing environment
  - Deployment: `student-dashboard-test`
  - Service: `student-dashboard-service-test`
  - Replicas: 1

- **production**: Production environment
  - Deployment: `student-dashboard-prod`
  - Service: `student-dashboard-service-prod`
  - Replicas: 3

## Prerequisites Summary

1. ✅ Docker installed and running
2. ✅ Kubernetes cluster accessible (Minikube, GKE, EKS, AKS, etc.)
3. ✅ Jenkins 2.x with required plugins
4. ✅ DockerHub account
5. ✅ kubectl configured
6. ✅ Git installed

## Quick Commands Reference

```bash
# Check application locally
cd student-dashboard
docker build -t test .
docker run -p 8080:80 test

# Check Kubernetes
kubectl get all -n test
kubectl get all -n production

# View logs
kubectl logs -n test -l app=student-dashboard
kubectl logs -n production -l app=student-dashboard

# Access application
kubectl port-forward svc/student-dashboard-service-test 8080:80 -n test

# Rollback
kubectl rollout undo deployment/student-dashboard-prod -n production
```

## Next Steps After Setup

1. ✅ Test pipeline with dev branch
2. ✅ Verify test deployment
3. ✅ Test pipeline with main branch
4. ✅ Verify production deployment
5. 🔄 Add automated testing stages
6. 🔄 Set up monitoring and alerting
7. 🔄 Configure webhooks for automatic triggers
8. 🔄 Add security scanning
9. 🔄 Implement blue-green deployments

---

**Ready to deploy? Start with README.md for detailed instructions!**

