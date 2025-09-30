# Deployment Guide

Complete guide for deploying the Pottery App to production environments.

## 🚀 Deployment Overview

The Pottery App uses a serverless architecture on Google Cloud Platform with automated CI/CD:

- **Backend**: FastAPI container on Cloud Run
- **Frontend**: Flutter web build on Firebase Hosting
- **Database**: Firestore with automated backups
- **Storage**: Cloud Storage with CDN
- **Authentication**: Firebase Auth with production OAuth

## 📋 Pre-Deployment Checklist

### Prerequisites

- [ ] Google Cloud Platform account with billing enabled
- [ ] Firebase project configured
- [ ] Domain name configured (optional)
- [ ] SSL certificates (handled by Firebase/Cloud Run)
- [ ] Production environment variables prepared

### Required Permissions

**GCP IAM Roles needed:**
- Cloud Run Admin
- Artifact Registry Admin
- Firestore User
- Storage Admin
- Firebase Admin
- Service Account Admin

## 🏗️ Production Infrastructure Setup

### 1. Create Production Firebase Project

Use the automated setup script:

```bash
cd backend/scripts
./setup-firebase-complete.sh
```

This creates:
- New GCP project: `pottery-app-prod`
- Firebase services enabled
- Web and Android app configurations
- Cloud Storage bucket: `pottery-app-prod-bucket`
- Firestore database in production mode

### 2. Configure Service Accounts

```bash
# Create runtime service account for Cloud Run
gcloud iam service-accounts create pottery-runtime-prod \
  --display-name="Pottery App Production Runtime" \
  --project=pottery-app-prod

# Create deployment service account
gcloud iam service-accounts create pottery-deploy-prod \
  --display-name="Pottery App Production Deployment" \
  --project=pottery-app-prod

# Grant necessary permissions
gcloud projects add-iam-policy-binding pottery-app-prod \
  --member="serviceAccount:pottery-runtime-prod@pottery-app-prod.iam.gserviceaccount.com" \
  --role="roles/datastore.user"

gcloud projects add-iam-policy-binding pottery-app-prod \
  --member="serviceAccount:pottery-runtime-prod@pottery-app-prod.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```

### 3. Configure OAuth for Production

1. **Google Cloud Console** → API Credentials
2. **Edit OAuth Client** for pottery-app-prod
3. **Add Production URLs**:
   ```
   Authorized JavaScript origins:
   - https://your-domain.com
   - https://pottery-app-prod.web.app

   Authorized redirect URIs:
   - https://your-domain.com/__/auth/handler
   - https://pottery-app-prod.web.app/__/auth/handler
   ```

## 🔧 Backend Deployment

### 1. Configure Production Environment

```bash
cd backend
cp .env.deploy.prod .env.deploy
```

Update `.env.deploy` with production values:

```bash
# Production GCP Configuration
GCP_PROJECT_ID=pottery-app-prod
GCS_BUCKET_NAME=pottery-app-prod-bucket

# Service Accounts
CLOUD_RUN_SERVICE_ACCOUNT_EMAIL=pottery-runtime-prod@pottery-app-prod.iam.gserviceaccount.com
DEPLOYMENT_SERVICE_ACCOUNT_EMAIL=pottery-deploy-prod@pottery-app-prod.iam.gserviceaccount.com
DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE=/path/to/prod-deploy-key.json

# Production Security Settings
JWT_SECRET_KEY=your-secure-256-bit-production-key
SIGNED_URL_EXPIRATION_MINUTES=5

# Performance Configuration
CLOUD_RUN_CPU=2
CLOUD_RUN_MEMORY=2Gi
CLOUD_RUN_MIN_INSTANCES=1
CLOUD_RUN_MAX_INSTANCES=100

# Build Configuration
BUILD_SERVICE_NAME=pottery-api-prod
BUILD_REGION=us-central1
BUILD_REPO_NAME=pottery-backend
```

### 2. Deploy to Cloud Run

```bash
cd backend
./build_and_deploy.sh
```

This script:
1. Authenticates with deployment service account
2. Creates Artifact Registry repository
3. Builds Docker image
4. Pushes to Artifact Registry
5. Deploys to Cloud Run with environment variables
6. Configures IAM permissions

### 3. Verify Backend Deployment

```bash
# Get Cloud Run service URL
gcloud run services describe pottery-api-prod \
  --region=us-central1 \
  --project=pottery-app-prod \
  --format="value(status.url)"

# Test health endpoint
curl https://pottery-api-prod-xxxxxxxx-uc.a.run.app/

# Test API documentation
open https://pottery-api-prod-xxxxxxxx-uc.a.run.app/api/docs
```

## 🌐 Frontend Deployment

### 1. Configure Production Firebase

Update `frontend/lib/firebase_options.dart` with production values:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'your-production-api-key',
  appId: 'your-production-app-id',
  messagingSenderId: 'your-sender-id',
  projectId: 'pottery-app-prod',
  authDomain: 'pottery-app-prod.firebaseapp.com',
  storageBucket: 'pottery-app-prod.firebasestorage.app',
  measurementId: 'your-measurement-id',
);
```

### 2. Build for Production

```bash
cd frontend

# Get production backend URL from Cloud Run
BACKEND_URL=$(gcloud run services describe pottery-api-prod \
  --region=us-central1 \
  --project=pottery-app-prod \
  --format="value(status.url)")

# Build Flutter web app
flutter build web \
  --dart-define=API_BASE_URL=$BACKEND_URL \
  --release \
  --web-renderer html
```

### 3. Deploy to Firebase Hosting

```bash
# Initialize Firebase hosting (one-time setup)
firebase init hosting --project pottery-app-prod

# Deploy to production
firebase deploy --project pottery-app-prod --only hosting
```

### 4. Configure Custom Domain (Optional)

```bash
# Add custom domain
firebase hosting:sites:create your-domain-com --project pottery-app-prod

# Configure domain
firebase hosting:sites:list --project pottery-app-prod
```

## 🔄 CI/CD Pipeline Setup

### 1. GitHub Actions Configuration

Create `.github/workflows/deploy-production.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Google Cloud
        uses: google-github-actions/setup-gcloud@v1
        with:
          project_id: pottery-app-prod
          service_account_key: ${{ secrets.GCP_SA_KEY }}

      - name: Deploy Backend
        run: |
          cd backend
          ./build_and_deploy.sh

  deploy-frontend:
    needs: deploy-backend
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'

      - name: Setup Firebase
        run: npm install -g firebase-tools

      - name: Build and Deploy Frontend
        run: |
          cd frontend
          flutter build web --dart-define=API_BASE_URL=${{ needs.deploy-backend.outputs.backend_url }}
          firebase deploy --project pottery-app-prod --only hosting
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```

### 2. Configure Secrets

In GitHub repository settings, add these secrets:

- `GCP_SA_KEY`: Production deployment service account key (JSON)
- `FIREBASE_TOKEN`: Firebase CI token (`firebase login:ci`)

### 3. Environment-Based Deployment

Create branch-based deployment:

```yaml
# .github/workflows/deploy-staging.yml
on:
  push:
    branches: [develop]

# Deploy to staging environment
# Uses pottery-app-staging project
```

## 📊 Production Monitoring Setup

### 1. Configure Monitoring

```bash
# Enable monitoring APIs
gcloud services enable monitoring.googleapis.com \
  --project=pottery-app-prod

# Create notification channels
gcloud alpha monitoring channels create \
  --display-name="Production Alerts" \
  --type=email \
  --channel-labels=email_address=alerts@yourcompany.com
```

### 2. Set Up Alerting Policies

```bash
# Create alerting policies for:
# - High error rate (>5%)
# - High latency (>1s)
# - Low availability (<99%)
# - Resource exhaustion

gcloud alpha monitoring policies create \
  --policy-from-file=monitoring/error-rate-policy.yaml
```

### 3. Configure Log Aggregation

```bash
# Create log-based metrics
gcloud logging metrics create pottery_errors \
  --description="Count of application errors" \
  --log-filter='resource.type="cloud_run_revision" AND severity>=ERROR'
```

## 🔐 Security Configuration

### 1. Network Security

```bash
# Configure Cloud Run to accept HTTPS only
gcloud run services update pottery-api-prod \
  --ingress=all \
  --region=us-central1 \
  --project=pottery-app-prod

# Set up Cloud Armor (if needed)
gcloud compute security-policies create pottery-security-policy \
  --description="Security policy for Pottery App"
```

### 2. IAM Security

```bash
# Remove default permissions
gcloud projects remove-iam-policy-binding pottery-app-prod \
  --member="allUsers" \
  --role="roles/viewer"

# Audit permissions
gcloud projects get-iam-policy pottery-app-prod \
  --format="table(bindings.role,bindings.members[])"
```

### 3. Data Security

- **Firestore Rules**: Ensure production rules require authentication
- **Storage Rules**: Verify file access controls
- **Environment Variables**: Use Secret Manager for sensitive values

## 🚨 Rollback Procedures

### Quick Rollback

```bash
# Rollback to previous Cloud Run revision
gcloud run services replace-traffic pottery-api-prod \
  --to-revisions=pottery-api-prod-00001-abc=100 \
  --region=us-central1 \
  --project=pottery-app-prod

# Rollback Firebase Hosting
firebase hosting:rollback --project pottery-app-prod
```

### Emergency Procedures

1. **Immediate Response**: Use Cloud Run traffic splitting (0% to new version)
2. **Investigation**: Check Cloud Monitoring and Cloud Logging
3. **Communication**: Update status page and notify stakeholders
4. **Resolution**: Fix issue and redeploy or complete rollback

## 📋 Post-Deployment Verification

### Automated Checks

```bash
# Health check script
./scripts/production-health-check.sh
```

### Manual Verification

1. **Frontend Access**: Verify app loads at production URL
2. **Authentication**: Test Google Sign-In flow
3. **API Functionality**: Test CRUD operations
4. **Photo Upload**: Verify file upload and storage
5. **Performance**: Check page load times
6. **Mobile Compatibility**: Test responsive design

### Monitoring Setup

- **Uptime Monitoring**: External monitoring service
- **Performance Monitoring**: Firebase Performance
- **Error Tracking**: Cloud Error Reporting
- **Analytics**: Firebase Analytics

## 📝 Deployment Checklist

### Pre-Deployment
- [ ] Code reviewed and tested
- [ ] Environment variables configured
- [ ] Service accounts created
- [ ] OAuth configured for production
- [ ] Database migrations prepared (if any)

### Deployment
- [ ] Backend deployed successfully
- [ ] Frontend built and deployed
- [ ] Database migrations executed (if any)
- [ ] CDN cache cleared
- [ ] SSL certificates verified

### Post-Deployment
- [ ] Health checks passing
- [ ] Authentication working
- [ ] Core functionality verified
- [ ] Performance metrics acceptable
- [ ] Monitoring alerts configured
- [ ] Documentation updated

---

*Next: [Environment Configuration](./environment-config.md)*
