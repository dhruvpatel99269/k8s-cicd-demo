# Jenkins Credentials Setup Guide

This guide will walk you through adding DockerHub credentials to Jenkins for your CI/CD pipeline.

## Step-by-Step Instructions

### Step 1: Access Jenkins Credentials

1. **Open Jenkins** in your browser
   - Usually at: `http://localhost:8080` (or your Jenkins URL)

2. **Login** to Jenkins with your admin credentials

3. **Navigate to Credentials**:
   - Click **Manage Jenkins** (left sidebar)
   - Click **Manage Credentials**

4. **Select Credential Domain**:
   - Under "Stores scoped to Jenkins", click on **Global** (or your preferred domain)
   - If you see "Global (unrestricted)" with a folder icon, click the folder to expand it

### Step 2: Add DockerHub Credentials

1. **Click "Add Credentials"** (left sidebar or the "+ Add" button)

2. **Configure Credentials**:
   
   - **Kind**: Select `Username with password` from the dropdown
   
   - **Scope**: Select `Global` (this makes it available to all jobs)
   
   - **Username**: 
     ```
     dhruv99269
     ```
   
   - **Password**: 
     - Enter your DockerHub password, OR
     - Better option: Enter your DockerHub **Access Token**
       - How to get access token:
         1. Go to https://hub.docker.com/settings/security
         2. Click "New Access Token"
         3. Give it a name (e.g., "Jenkins-CICD")
         4. Copy the token (you'll only see it once!)
         5. Paste it here
   
   - **ID**: 
     ```
     dockerhub-credentials
     ```
     ⚠️ **IMPORTANT**: This ID must match exactly what's in your Jenkinsfile!
   
   - **Description** (optional):
     ```
     DockerHub credentials for dhruv99269 - k8s-cicd-demo
     ```

3. **Click "OK"** to save

### Step 3: Verify Credentials

1. You should now see your credentials listed under the Global domain
2. Check that the **ID** is exactly `dockerhub-credentials`
3. The username should show as `dhruv99269`

### Step 4: (Optional) Add Kubernetes Credentials

If your Jenkins is not running inside the Kubernetes cluster, you may need to add kubeconfig:

1. **Click "Add Credentials"** again

2. **Configure**:
   - **Kind**: Select `Secret file`
   - **Scope**: `Global`
   - **File**: Upload your `kubeconfig` file
     - Usually located at: `~/.kube/config` (Linux/Mac) or `%USERPROFILE%\.kube\config` (Windows)
   - **ID**: `kubeconfig-credentials`
   - **Description**: `Kubernetes kubeconfig for cluster access`

3. **Click "OK"**

**Note**: If Jenkins is running inside Kubernetes, it may use the service account automatically.

---

## How to Get DockerHub Access Token

### Option 1: Using DockerHub Website

1. Go to: https://hub.docker.com/
2. Login with your account (`dhruv99269`)
3. Click your profile icon (top right) → **Account Settings**
4. Click **Security** (left sidebar)
5. Click **New Access Token**
6. **Token name**: `Jenkins-CICD` (or any name you prefer)
7. **Permissions**: Select `Read, Write & Delete` (or at least `Read & Write`)
8. Click **Generate**
9. **Copy the token immediately** (you won't see it again!)
10. Paste it into Jenkins credentials as the Password

### Option 2: Using Docker CLI

If you prefer, you can also use your DockerHub password directly, but access tokens are more secure.

---

## Troubleshooting

### Issue: Credentials not found error

**Error Message**: 
```
Credentials 'dockerhub-credentials' not found
```

**Solution**:
1. Verify the ID is exactly `dockerhub-credentials` (case-sensitive)
2. Check that the scope is `Global`
3. Make sure you saved the credentials correctly

### Issue: Authentication failed

**Error Message**:
```
unauthorized: authentication required
```

**Solution**:
1. Verify your DockerHub username is correct: `dhruv99269`
2. Verify your password/token is correct
3. Test login manually:
   ```bash
   docker login
   # Enter username: dhruv99269
   # Enter password/token
   ```
4. If manual login works, the credentials in Jenkins might be wrong - re-enter them

### Issue: Credentials not visible in pipeline

**Solution**:
1. Make sure credentials are in `Global` scope
2. Check the credentials ID matches exactly: `dockerhub-credentials`
3. Restart Jenkins if needed:
   ```bash
   # Linux
   sudo systemctl restart jenkins
   
   # Or via Jenkins UI: Manage Jenkins → Reload Configuration from Disk
   ```

### Issue: How to update credentials

1. Go to **Manage Jenkins → Manage Credentials**
2. Find your credentials under Global
3. Click on the credential name (or the dropdown arrow)
4. Click **Update**
5. Modify as needed
6. Click **Save**

---

## Quick Verification Test

After adding credentials, you can test them:

### Test 1: Check in Jenkins

1. Go to any pipeline job
2. In the pipeline configuration, try to reference the credentials
3. The credentials should appear in dropdowns if configured correctly

### Test 2: Test Pipeline Build

1. Run your pipeline job
2. Watch the "Push to DockerHub" stage
3. It should successfully push without authentication errors

### Test 3: Manual Docker Login Test

```bash
# Test credentials work manually
docker login
# Username: dhruv99269
# Password: [your token or password]

# Try to push a test image
docker tag test-image dhruv99269/k8s-cicd-demo:test
docker push dhruv99269/k8s-cicd-demo:test
```

---

## Credentials Summary

After setup, you should have:

| Credential ID | Type | Username | Purpose |
|--------------|------|----------|---------|
| `dockerhub-credentials` | Username with password | `dhruv99269` | Push images to DockerHub |
| `kubeconfig-credentials` (optional) | Secret file | N/A | Access Kubernetes cluster |

---

## Security Best Practices

✅ **Use Access Tokens** instead of passwords  
✅ **Set minimal required permissions** for tokens  
✅ **Use Global scope** only if needed by multiple jobs  
✅ **Rotate tokens** periodically  
✅ **Don't commit credentials** to Git  
✅ **Use Jenkins Credentials** instead of hardcoding  

---

## Next Steps

After adding credentials:

1. ✅ Verify credentials are saved correctly
2. ✅ Test pipeline manually to verify credentials work
3. ✅ Run full pipeline with dev branch
4. ✅ Check DockerHub to see pushed images

---

**Your credentials are now configured! The pipeline should be able to push images to DockerHub successfully. 🚀**

