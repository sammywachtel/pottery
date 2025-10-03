# Production Environment Setup Guide

Complete step-by-step guide for setting up the Pottery API in production from scratch.

## Prerequisites

- Google Cloud SDK (`gcloud`) installed locally
- Access to Google Cloud console
- Owner or Editor role on the GCP project
- Docker installed (for local testing)

## Overview

This guide will walk you through:
1. Creating a production GCP project
2. Setting up deployment service account (for CI/CD)
3. Setting up runtime service account (for the API)
4. Configuring production environment variables
5. Creating GCS bucket and infrastructure
6. Deploying to Cloud Run
7. Verifying the deployment

**Estimated time:** 30-45 minutes

---

## Step 1: Create Production GCP Project

### 1.1 Create the Project

```bash
# Create new GCP project
gcloud projects create pottery-app-prod --name="Pottery App Production"

# Set as default project
gcloud config set project pottery-app-prod

# Enable billing (must be done via console)
# Visit: https://console.cloud.google.com/billing
```

### 1.2 Enable Required APIs

```bash
# Enable all required APIs
gcloud services enable \
  iam.googleapis.com \
  storage.googleapis.com \
  storage-api.googleapis.com \
  firestore.googleapis.com \
  firebase.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com
```

**⏱️ Wait time:** 2-3 minutes for API enablement

---

## Step 2: Create Deployment Service Account

This service account is used by your CI/CD pipeline or local machine to deploy to Cloud Run.

### 2.1 Authenticate with Your User Account

```bash
# Use your personal account for setup
gcloud auth login
gcloud config set project pottery-app-prod
```

### 2.2 Create the Deployment Service Account

```bash
# Create service account
gcloud iam service-accounts create pottery-app-install-sa-prod \
  --display-name="Pottery App Deployment Service Account" \
  --description="Used for deploying backend to Cloud Run" \
  --project=pottery-app-prod
```

### 2.3 Grant Deployment Roles

```bash
PROJECT_ID="pottery-app-prod"
SA_EMAIL="pottery-app-install-sa-prod@${PROJECT_ID}.iam.gserviceaccount.com"

# Grant all required roles for deployment
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/artifactregistry.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudbuild.connectionViewer"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/logging.viewer"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/resourcemanager.projectIamAdmin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/secretmanager.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountAdmin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountKeyAdmin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/serviceusage.serviceUsageAdmin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/serviceusage.serviceUsageConsumer"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.objectViewer"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/viewer"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/datastore.owner"
```

**⏱️ Wait time:** 1-2 minutes for role propagation

### 2.4 Create and Download Key File

```bash
# Create key file in secure location
gcloud iam service-accounts keys create \
  ~/.gsutil/pottery-app-install-sa-prod-key.json \
  --iam-account=${SA_EMAIL} \
  --project=${PROJECT_ID}

# Secure the key file
chmod 600 ~/.gsutil/pottery-app-install-sa-prod-key.json
```

**🔒 Security Note:** Keep this key file secure and never commit to version control!

---

## Step 3: Create Runtime Service Account

This service account is used by the Cloud Run service to access GCS, Firestore, and Firebase.

### 3.1 Authenticate with Deployment Service Account

```bash
# Switch to deployment service account
gcloud auth activate-service-account \
  --key-file=~/.gsutil/pottery-app-install-sa-prod-key.json \
  --project=pottery-app-prod
```

### 3.2 Run Service Account Setup Script

```bash
# Navigate to scripts directory
cd /path/to/pottery-backend/scripts/backend

# Run setup script
./setup-service-account.sh pottery-app-prod
```

This creates `pottery-app-sa@pottery-app-prod.iam.gserviceaccount.com` with roles:
- Cloud Datastore User (Firestore access)
- Firebase Viewer (Firebase Auth verification)
- Storage Admin (GCS bucket management and CORS)
- Storage Object Admin (GCS object read/write)

### 3.3 Create Runtime Service Account Key (Optional)

When prompted, create a key file if you want to test production configuration locally.

**⏱️ Wait time:** 1-2 minutes for script completion

---

## Step 4: Configure Production Environment

### 4.1 Create `.env.prod` File

```bash
# Navigate to backend directory
cd /path/to/pottery-backend/backend

# Copy template
cp .env.deploy.example .env.prod
```

### 4.2 Edit `.env.prod` with Production Values

```bash
# Environment Identification
ENVIRONMENT=production

# Google Cloud Project Configuration
GCP_PROJECT_ID=pottery-app-prod
GCS_BUCKET_NAME=pottery-app-prod-bucket

# Firestore Configuration
FIRESTORE_COLLECTION=pottery_items
FIRESTORE_DATABASE_ID="(default)"

# Firebase Authentication
FIREBASE_PROJECT_ID=pottery-app-prod
FIREBASE_AUTH_DOMAIN=pottery-app-prod.firebaseapp.com

# Application Configuration
PORT=8080
SIGNED_URL_EXPIRATION_MINUTES=5

# JWT Configuration (LEGACY - for backward compatibility, not actively used with Firebase Auth)
# TODO: Remove JWT_SECRET_KEY after confirming no legacy usage
JWT_SECRET_KEY=GENERATE-SECURE-32-CHAR-MINIMUM-STRING-HERE
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=15

# Cloud Run Deployment
BUILD_SERVICE_NAME=pottery-api-prod
BUILD_REGION=us-central1
BUILD_REPO_NAME=pottery-backend
CLOUD_RUN_SERVICE_ACCOUNT_EMAIL=pottery-app-sa@pottery-app-prod.iam.gserviceaccount.com

# Deployment Service Account
DEPLOYMENT_SERVICE_ACCOUNT_EMAIL=pottery-app-install-sa-prod@pottery-app-prod.iam.gserviceaccount.com
DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE=/Users/YOUR_USERNAME/.gsutil/pottery-app-install-sa-prod-key.json

# Production Security Settings
LOG_LEVEL=WARNING
DEBUG_MODE=false

# Resource Limits
CLOUD_RUN_CPU=2
CLOUD_RUN_MEMORY=2Gi
CLOUD_RUN_MIN_INSTANCES=1
CLOUD_RUN_MAX_INSTANCES=100
```

**📝 Note:** JWT_SECRET_KEY is legacy - not actively used with Firebase Auth. Still include it for backward compatibility:
```bash
# Generate secure random string (for legacy compatibility)
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```
**TODO:** Can be removed after confirming no legacy endpoints depend on it.

---

## Step 5: Create GCS Bucket and Setup Infrastructure

### 5.1 Create Production GCS Bucket

```bash
# Create bucket with uniform access control
gcloud storage buckets create gs://pottery-app-prod-bucket \
  --project=pottery-app-prod \
  --location=us-central1 \
  --uniform-bucket-level-access
```

### 5.2 Configure CORS for Browser Access

```bash
# Navigate to scripts directory
cd /path/to/pottery-backend/scripts/backend

# Apply production CORS configuration
./setup-infrastructure.sh prod
```

This configures the GCS bucket to allow:
- Browser-based image loading
- Signed URL access from your production domains
- Proper CORS headers for frontend apps

**⏱️ Wait time:** 2-5 minutes for CORS propagation

---

## Step 6: Create Firestore Database

### 6.1 Create Firestore in Native Mode

```bash
# Create Firestore database
gcloud firestore databases create \
  --location=us-central1 \
  --project=pottery-app-prod
```

**Note:** This creates a Firestore database in Native mode. You can only have one Firestore database per project.

**⏱️ Wait time:** 3-5 minutes for database creation

---

## Step 7: Deploy to Cloud Run

### 7.1 Run Deployment Script

```bash
# Navigate to scripts directory
cd /path/to/pottery-backend/scripts/backend

# Deploy to production
./build_and_deploy.sh --env=prod
```

The deployment process will:
1. Authenticate with deployment service account
2. Create Artifact Registry repository (if needed)
3. Build Docker image using Cloud Build
4. Push image to Artifact Registry
5. Deploy to Cloud Run with production configuration
6. Configure GCS CORS settings
7. Fix signed URL generation

**⏱️ Wait time:** 5-10 minutes for initial deployment

### 7.2 Deployment Output

Save the Cloud Run service URL from the deployment output:
```
Service [pottery-api-prod] revision [pottery-api-prod-00001-xxx] has been deployed
Service URL: https://pottery-api-prod-xxxxx-uc.a.run.app
```

---

## Step 8: Verify Deployment

### 8.1 Test Health Endpoint

```bash
# Test the health endpoint
curl https://pottery-api-prod-xxxxx-uc.a.run.app/

# Expected response:
# {"status":"ok","message":"Pottery API is running"}
```

### 8.2 Test API Documentation

Visit in browser:
- Swagger UI: `https://pottery-api-prod-xxxxx-uc.a.run.app/api/docs`
- ReDoc: `https://pottery-api-prod-xxxxx-uc.a.run.app/api/redoc`

### 8.3 Test Authenticated Endpoint (Optional)

```bash
# Get Firebase ID token from your Flutter app
export TOKEN="your-firebase-id-token"

# Test authenticated endpoint
curl -H "Authorization: Bearer ${TOKEN}" \
  https://pottery-api-prod-xxxxx-uc.a.run.app/api/items
```

---

## Step 9: Update Frontend Configuration

### 9.1 Update Flutter App Environment

The Flutter app uses `--dart-define` at build time (no hardcoded file needed).

**Option A: Use default production URL (automatic)**
```bash
cd frontend/scripts
./build_prod.sh  # Uses default prod URL
```

**Option B: Override with custom URL**
```bash
API_BASE_URL=https://pottery-api-prod-xxxxx-uc.a.run.app ./build_prod.sh
```

**Option C: Edit the build script permanently**
Update `frontend/scripts/build_prod.sh`:
```bash
API_BASE_URL="${API_BASE_URL:-https://pottery-api-prod-xxxxx-uc.a.run.app}"
```

### 9.2 Update CORS Configuration (if needed)

If your frontend runs on specific domains, update CORS configuration:

```bash
# Edit infrastructure/cors-config.prod.json
# Add your production frontend domains

# Re-apply CORS
./setup-infrastructure.sh prod
```

---

## Troubleshooting

### Deployment Fails with Permission Errors

**Problem:** `Permission denied` errors during deployment

**Solution:**
1. Verify deployment service account has all required roles
2. Wait 2-3 minutes for IAM changes to propagate
3. Re-run deployment script

### Images Not Loading in Frontend

**Problem:** CORS errors in browser console

**Solution:**
1. Verify CORS configuration: `./manage-cors.sh status`
2. Update `infrastructure/cors-config.prod.json` with your domains
3. Re-apply: `./setup-infrastructure.sh prod`
4. Wait 2-5 minutes for propagation
5. Hard refresh browser (Ctrl+F5)

### Cloud Run Service Won't Start

**Problem:** Service shows "Revision failed"

**Solution:**
1. Check Cloud Run logs: `gcloud run services logs read pottery-api-prod --region=us-central1`
2. Verify all environment variables are set correctly in `.env.prod`
3. Verify runtime service account has required permissions
4. Check Firestore database exists and is accessible

---

## Security Checklist

Before going live:

- [ ] JWT_SECRET_KEY is a secure random string (not the example value)
- [ ] Deployment service account key is stored securely
- [ ] Runtime service account key (if created) is stored securely
- [ ] `.env.prod` is added to `.gitignore`
- [ ] CORS configuration only allows production domains
- [ ] Cloud Run service has min/max instance limits set
- [ ] Firestore security rules are configured
- [ ] Firebase Authentication is properly configured

---

## Next Steps

- **Monitoring:** Set up Cloud Monitoring alerts
- **Logging:** Configure log retention policies
- **Backups:** Set up automated Firestore backups
- **CI/CD:** Automate deployments with GitHub Actions
- **Custom Domain:** Configure custom domain for Cloud Run
- **SSL Certificate:** Set up SSL certificate

## Reference

- [Environment Variables Reference](../reference/environment-variables.md)
- [Scripts Reference](../reference/scripts.md)
- [Troubleshooting Guide](troubleshoot-common-issues.md)
- [Architecture Overview](../explanation/architecture.md)
