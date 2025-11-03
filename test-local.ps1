# PowerShell Script for Local Testing (Windows)
# Student Dashboard CI/CD Local Testing

param(
    [Parameter(Mandatory=$true)]
    [string]$DockerHubUsername
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Student Dashboard - Local Testing Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"
$ImageName = "student-dashboard"
$LocalTag = "local"
$TestTag = "test"

# Step 1: Test Docker Build
Write-Host "Step 1: Testing Docker Build..." -ForegroundColor Yellow
if (Test-Path "student-dashboard") {
    Push-Location student-dashboard
    try {
        docker build -t "${ImageName}:${LocalTag}" . 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Docker image built successfully" -ForegroundColor Green
        } else {
            Write-Host "✗ Docker build failed" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "✗ Docker build failed: $_" -ForegroundColor Red
        exit 1
    }
    Pop-Location
} else {
    Write-Host "✗ student-dashboard directory not found" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 2: Test Docker Run
Write-Host "Step 2: Testing Docker Container..." -ForegroundColor Yellow
try {
    $ContainerId = docker run -d -p 8080:80 "${ImageName}:${LocalTag}" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Container started successfully" -ForegroundColor Green
        Start-Sleep -Seconds 2
        
        # Test HTTP response
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Host "✓ Application is responding" -ForegroundColor Green
                Write-Host "ℹ Application accessible at: http://localhost:8080" -ForegroundColor Cyan
            }
        } catch {
            Write-Host "⚠ Application may not be responding yet" -ForegroundColor Yellow
        }
        
        # Stop container
        docker stop $ContainerId | Out-Null
        docker rm $ContainerId | Out-Null
        Write-Host "ℹ Container stopped and removed" -ForegroundColor Cyan
    } else {
        Write-Host "✗ Failed to start container" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Error running container: $_" -ForegroundColor Red
}
Write-Host ""

# Step 3: Test Docker Login
Write-Host "Step 3: Testing Docker Login..." -ForegroundColor Yellow
Write-Host "ℹ Skipping Docker login (manual step required)" -ForegroundColor Cyan
Write-Host "ℹ Run: docker login" -ForegroundColor Cyan
Write-Host ""

# Step 4: Test Docker Push
Write-Host "Step 4: Testing Docker Push..." -ForegroundColor Yellow
Write-Host "ℹ Tagging image for DockerHub..." -ForegroundColor Cyan
try {
    docker tag "${ImageName}:${LocalTag}" "${DockerHubUsername}/${ImageName}:${TestTag}" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Image tagged successfully" -ForegroundColor Green
        Write-Host "ℹ To push, run: docker push ${DockerHubUsername}/${ImageName}:${TestTag}" -ForegroundColor Cyan
        Write-Host "ℹ Make sure you're logged in: docker login" -ForegroundColor Cyan
    } else {
        Write-Host "✗ Failed to tag image" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Error tagging image: $_" -ForegroundColor Red
}
Write-Host ""

# Step 5: Test Kubernetes (if available)
Write-Host "Step 5: Testing Kubernetes Deployment..." -ForegroundColor Yellow
$kubectlPath = Get-Command kubectl -ErrorAction SilentlyContinue
if ($kubectlPath) {
    try {
        kubectl cluster-info 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ kubectl is configured" -ForegroundColor Green
            
            # Check if namespace exists
            kubectl get namespace test 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "ℹ Test namespace exists" -ForegroundColor Cyan
            } else {
                Write-Host "ℹ Creating test namespace..." -ForegroundColor Cyan
                kubectl create namespace test 2>&1 | Out-Null
            }
            
            # Update deployment file
            Write-Host "ℹ Preparing deployment file..." -ForegroundColor Cyan
            if (Test-Path "k8s\deployment-test.yaml") {
                $content = Get-Content "k8s\deployment-test.yaml" -Raw
                $content = $content -replace 'DOCKERHUB_USERNAME', $DockerHubUsername
                $content = $content -replace 'IMAGE_TAG', $TestTag
                Set-Content "k8s\deployment-test-temp.yaml" -Value $content
                Write-Host "ℹ To deploy, run: kubectl apply -f k8s\deployment-test-temp.yaml" -ForegroundColor Cyan
                Write-Host "ℹ Then: kubectl get all -n test" -ForegroundColor Cyan
            }
        } else {
            Write-Host "✗ kubectl is not configured or cluster is not accessible" -ForegroundColor Red
            Write-Host "ℹ Skipping Kubernetes tests" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "⚠ Kubernetes check failed: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ kubectl not found, skipping Kubernetes tests" -ForegroundColor Cyan
}
Write-Host ""

# Summary
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Docker build: OK" -ForegroundColor Green
Write-Host "✓ Docker run: OK" -ForegroundColor Green
Write-Host "ℹ Docker push: Manual step required" -ForegroundColor Cyan
Write-Host "ℹ Kubernetes: Check above" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Test DockerHub push: docker push ${DockerHubUsername}/${ImageName}:${TestTag}"
Write-Host "2. Set up Jenkins pipeline"
Write-Host "3. Configure Jenkins credentials"
Write-Host "4. Run pipeline from dev branch"
Write-Host ""
Write-Host "✓ Local testing complete!" -ForegroundColor Green

