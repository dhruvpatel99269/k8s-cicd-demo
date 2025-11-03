#!/bin/bash

# Local Testing Script for Student Dashboard CI/CD
# This script helps you test components locally before using Jenkins

set -e  # Exit on error

echo "========================================="
echo "Student Dashboard - Local Testing Script"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOCKERHUB_USERNAME=""
IMAGE_NAME="student-dashboard"
LOCAL_TAG="local"
TEST_TAG="test"

# Functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if DockerHub username is provided
if [ -z "$1" ]; then
    echo "Usage: ./test-local.sh <DOCKERHUB_USERNAME>"
    echo "Example: ./test-local.sh myusername"
    exit 1
fi

DOCKERHUB_USERNAME=$1

echo "Testing with DockerHub username: $DOCKERHUB_USERNAME"
echo ""

# Step 1: Test Docker Build
echo "Step 1: Testing Docker Build..."
if [ -d "student-dashboard" ]; then
    cd student-dashboard
    if docker build -t ${IMAGE_NAME}:${LOCAL_TAG} . > /dev/null 2>&1; then
        print_success "Docker image built successfully"
    else
        print_error "Docker build failed"
        exit 1
    fi
    cd ..
else
    print_error "student-dashboard directory not found"
    exit 1
fi
echo ""

# Step 2: Test Docker Run
echo "Step 2: Testing Docker Container..."
CONTAINER_ID=$(docker run -d -p 8080:80 ${IMAGE_NAME}:${LOCAL_TAG} 2>/dev/null)
if [ $? -eq 0 ]; then
    print_success "Container started successfully"
    sleep 2
    
    # Test HTTP response
    if curl -s http://localhost:8080 > /dev/null; then
        print_success "Application is responding"
        print_info "Application accessible at: http://localhost:8080"
    else
        print_error "Application is not responding"
    fi
    
    # Stop container
    docker stop $CONTAINER_ID > /dev/null 2>&1
    docker rm $CONTAINER_ID > /dev/null 2>&1
    print_info "Container stopped and removed"
else
    print_error "Failed to start container"
fi
echo ""

# Step 3: Test Docker Login (optional)
echo "Step 3: Testing Docker Login..."
print_info "Skipping Docker login (manual step required)"
print_info "Run: docker login"
echo ""

# Step 4: Test Docker Push
echo "Step 4: Testing Docker Push..."
print_info "Tagging image for DockerHub..."
docker tag ${IMAGE_NAME}:${LOCAL_TAG} ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${TEST_TAG} > /dev/null 2>&1

if [ $? -eq 0 ]; then
    print_success "Image tagged successfully"
    print_info "To push, run: docker push ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${TEST_TAG}"
    print_info "Make sure you're logged in: docker login"
else
    print_error "Failed to tag image"
fi
echo ""

# Step 5: Test Kubernetes (if available)
echo "Step 5: Testing Kubernetes Deployment..."
if command -v kubectl &> /dev/null; then
    if kubectl cluster-info &> /dev/null; then
        print_success "kubectl is configured"
        
        # Check if namespace exists
        if kubectl get namespace test &> /dev/null; then
            print_info "Test namespace exists"
        else
            print_info "Creating test namespace..."
            kubectl create namespace test 2>/dev/null || true
        fi
        
        # Update deployment file
        print_info "Preparing deployment file..."
        cp k8s/deployment-test.yaml k8s/deployment-test-temp.yaml
        sed -i.bak "s|DOCKERHUB_USERNAME|${DOCKERHUB_USERNAME}|g" k8s/deployment-test-temp.yaml
        sed -i.bak "s|IMAGE_TAG|${TEST_TAG}|g" k8s/deployment-test-temp.yaml
        rm -f k8s/deployment-test-temp.yaml.bak
        
        print_info "To deploy, run: kubectl apply -f k8s/deployment-test-temp.yaml"
        print_info "Then: kubectl get all -n test"
    else
        print_error "kubectl is not configured or cluster is not accessible"
        print_info "Skipping Kubernetes tests"
    fi
else
    print_info "kubectl not found, skipping Kubernetes tests"
fi
echo ""

# Summary
echo "========================================="
echo "Test Summary"
echo "========================================="
echo ""
print_success "Docker build: OK"
print_success "Docker run: OK"
print_info "Docker push: Manual step required"
print_info "Kubernetes: Check above"
echo ""
echo "Next steps:"
echo "1. Test DockerHub push: docker push ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${TEST_TAG}"
echo "2. Set up Jenkins pipeline"
echo "3. Configure Jenkins credentials"
echo "4. Run pipeline from dev branch"
echo ""
print_success "Local testing complete!"

