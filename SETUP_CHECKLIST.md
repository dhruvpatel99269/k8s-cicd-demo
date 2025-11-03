# Setup Checklist - CI/CD Pipeline

Use this checklist to ensure all components are properly configured before running the pipeline.

## Pre-Setup Requirements

- [ ] Docker installed and running (`docker --version`)
- [ ] Kubernetes cluster accessible (`kubectl cluster-info`)
- [ ] Jenkins installed and accessible (http://localhost:8080 or your Jenkins URL)
- [ ] Git installed (`git --version`)
- [ ] DockerHub account created
- [ ] DockerHub access token generated

## Jenkins Configuration

- [ ] Jenkins plugins installed:
  - [ ] Pipeline
  - [ ] Docker Pipeline
  - [ ] Kubernetes CLI
  - [ ] Git

- [ ] DockerHub credentials added to Jenkins
  - ID: `dockerhub-credentials`
  - Type: Username with password
  - Contains: DockerHub username and access token

- [ ] Kubernetes credentials configured (if needed)
  - ID: `kubeconfig-credentials`
  - Type: Secret file (kubeconfig)

- [ ] Jenkinsfile updated with your DockerHub username
  - Replace `YOUR_DOCKERHUB_USERNAME` in Jenkinsfile

## Kubernetes Configuration

- [ ] Kubernetes cluster is running
- [ ] kubectl configured correctly (`kubectl get nodes`)
- [ ] Namespaces will be created automatically (test, production)
- [ ] Cluster has sufficient resources

## Git Repository Setup

- [ ] Git repository initialized
- [ ] All files committed
- [ ] `dev` branch created
- [ ] `main` branch created
- [ ] Remote repository configured (if using remote)
- [ ] Webhook configured (optional but recommended)

## Jenkins Pipeline Job

- [ ] Pipeline job created in Jenkins
- [ ] Pipeline configured to use Jenkinsfile from SCM
- [ ] Repository URL configured correctly
- [ ] Branch specifier configured (*/dev and */main)
- [ ] Job saved

## Initial Testing

- [ ] Test Docker build locally
  ```bash
  cd student-dashboard
  docker build -t student-dashboard:test .
  docker run -p 8080:80 student-dashboard:test
  ```

- [ ] Test Docker login
  ```bash
  docker login
  docker push your-username/student-dashboard:test
  ```

- [ ] Test kubectl connection
  ```bash
  kubectl get nodes
  kubectl get namespaces
  ```

## First Pipeline Run

- [ ] Trigger pipeline on dev branch
- [ ] Verify all stages complete successfully:
  - [ ] Checkout
  - [ ] Build Docker Image
  - [ ] Push to DockerHub
  - [ ] Deploy to Kubernetes (test)
  - [ ] Verification

- [ ] Check deployment in Kubernetes
  ```bash
  kubectl get all -n test
  ```

- [ ] Access application and verify it works

## Production Deployment

- [ ] Merge or push to main branch
- [ ] Trigger pipeline on main branch
- [ ] Verify deployment to production namespace
- [ ] Check production deployment
  ```bash
  kubectl get all -n production
  ```

## Verification Commands

```bash
# Check test environment
kubectl get deployments -n test
kubectl get pods -n test
kubectl get services -n test
kubectl describe deployment student-dashboard-test -n test

# Check production environment
kubectl get deployments -n production
kubectl get pods -n production
kubectl get services -n production
kubectl describe deployment student-dashboard-prod -n production

# Check images in DockerHub
# Visit: https://hub.docker.com/r/your-username/student-dashboard
```

## Troubleshooting Checklist

If pipeline fails:

- [ ] Check Jenkins console output for errors
- [ ] Verify Docker is running and accessible
- [ ] Verify DockerHub credentials are correct
- [ ] Verify kubectl is accessible from Jenkins
- [ ] Check Kubernetes cluster is healthy
- [ ] Verify deployment YAML files are correct
- [ ] Check Jenkins workspace for build artifacts
- [ ] Review Jenkins logs (`/var/log/jenkins/jenkins.log` on Linux)

---

**Once all items are checked, your CI/CD pipeline is ready! 🎉**

