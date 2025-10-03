# Environment Setup Guide

Configure development and production environments for the Pottery App.

## 🏗️ Environment Overview

The Pottery App supports two environments with separate configurations:

| Environment | Purpose | Backend Config | Firebase Project |
|-------------|---------|----------------|------------------|
| **Development** | Local development | `.env.local` | `pottery-app-456522` |
| **Production** | Live deployment | `.env.deploy.prod` | `pottery-app-prod` |

## 🚀 Development Environment

### Backend Configuration

The development environment uses Docker for the backend with local Firebase integration.

**Configuration File**: `backend/.env.local`

```bash
# Google Cloud & Firebase
GCP_PROJECT_ID="pottery-app-456522"
GCS_BUCKET_NAME="pottery-app-456522-bucket"
FIREBASE_PROJECT_ID="pottery-app-456522"

# Local Docker settings
LOCAL_PORT=8000
PORT=8080
HOST_KEY_PATH="/Users/yourusername/.gsutil/pottery-app-sa-456522-xxx.json"

# Authentication
JWT_SECRET_KEY="your-secret-key-for-development-only"
FIREBASE_AUTH_DOMAIN="pottery-app-456522.firebaseapp.com"
```

### Frontend Configuration

Flutter web app with development Firebase config.

**Configuration File**: `frontend/lib/firebase_options.dart`

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyD9_T4dzS6pdBL5QLB6Q4X3SDr7_tH0eg0',
  appId: '1:1073709451179:web:92276550af84ff06feb4ee',
  messagingSenderId: '1073709451179',
  projectId: 'pottery-app-456522',
  authDomain: 'pottery-app-456522.firebaseapp.com',
  storageBucket: 'pottery-app-456522.firebasestorage.app',
  measurementId: 'G-7Y02GN2Q86',
);
```

### Running Development Environment

```bash
# Start backend
cd backend
./run_docker_local.sh

# Start frontend (in new terminal)
cd frontend
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --web-hostname localhost \
  --web-port 9100
```

**Access Points:**
- Frontend: `http://localhost:9100`
- Backend API: `http://localhost:8000`
- API Docs: `http://localhost:8000/api/docs`

## 🧪 Running Tests

```bash
# Backend unit tests
cd backend
pytest -m "not integration"

# Backend integration tests (uses development GCP project)
pytest -m integration

# Frontend tests
cd frontend
flutter test
```

## 🏭 Production Environment

### Create Production Firebase Project

Use the automated setup script to create the production Firebase project:

```bash
cd scripts/backend
./setup-firebase-complete.sh
```

This script will:
- Create `pottery-app-prod` GCP project
- Set up Firebase services
- Create web and Android app configurations
- Generate production environment files

### Production Configuration

**Backend Config**: `backend/.env.deploy.prod`

```bash
# Production GCP settings
GCP_PROJECT_ID=pottery-app-prod
GCS_BUCKET_NAME=pottery-app-prod-bucket

# Production service accounts
CLOUD_RUN_SERVICE_ACCOUNT_EMAIL=pottery-runtime-prod@pottery-app-prod.iam.gserviceaccount.com
DEPLOYMENT_SERVICE_ACCOUNT_EMAIL=deploy-prod@pottery-app-prod.iam.gserviceaccount.com

# Production security
JWT_SECRET_KEY=CHANGE-THIS-TO-SECURE-RANDOM-STRING-32-CHARS-MIN
SIGNED_URL_EXPIRATION_MINUTES=5

# Production performance
CLOUD_RUN_CPU=2
CLOUD_RUN_MEMORY=2Gi
CLOUD_RUN_MIN_INSTANCES=1
CLOUD_RUN_MAX_INSTANCES=100
```

### Production Deployment

```bash
# Deploy backend to Cloud Run
cd backend
cp .env.deploy.prod .env.deploy
./build_and_deploy.sh

# Build frontend for production
cd frontend
flutter build web --dart-define=API_BASE_URL=https://your-production-url
```

## 🔧 Environment Switching

### Quick Environment Commands

```bash
# Development
./scripts/dev-start.sh

# Production deployment
./scripts/prod-deploy.sh
```

### Environment Variables Reference

| Variable | Dev | Prod | Description |
|----------|-----|------|-------------|
| `GCP_PROJECT_ID` | `pottery-app-456522` | `pottery-app-prod` | Google Cloud Project |
| `GCS_BUCKET_NAME` | `pottery-app-456522-bucket` | `pottery-app-prod-bucket` | Storage bucket |
| `LOCAL_PORT` | `8000` | N/A | Local backend port |
| `JWT_SECRET_KEY` | Development key | Secure prod key | JWT signing key |
| `SIGNED_URL_EXPIRATION_MINUTES` | `15` | `5` | Photo URL expiration |

## 🔐 Authentication Configuration

### Google OAuth Setup

Each environment requires OAuth client configuration:

```bash
# Development URLs
http://localhost:9100
http://localhost:9100/__/auth/handler

# Production URLs
https://your-domain.com
https://your-domain.com/__/auth/handler
```

### Firebase Authentication

Configure in Firebase Console for each environment:
1. Enable Google Sign-In provider
2. Add authorized domains
3. Configure OAuth consent screen

## 📋 Environment Checklist

### Development Setup ✅
- [ ] `.env.local` configured
- [ ] Docker running
- [ ] Firebase project `pottery-app-456522` accessible
- [ ] Service account key file present
- [ ] OAuth client configured for localhost

### Production Setup
- [ ] Production Firebase project created
- [ ] `.env.deploy.prod` with secure values
- [ ] Production service accounts created
- [ ] OAuth client configured for production domain
- [ ] Cloud Run deployment working

## 🆘 Troubleshooting

### Common Issues

**Docker Backend Won't Start**
```bash
# Check Docker status
docker ps

# Check environment file
cat backend/.env.local

# Rebuild container
cd backend && ./run_docker_local.sh --rebuild
```

**Firebase Authentication Fails**
```bash
# Verify Firebase config
firebase projects:list

# Check OAuth client
gcloud auth application-default login
```

**Environment Variable Issues**
```bash
# Load and verify environment
cd backend
source .env.local
echo $GCP_PROJECT_ID
```

---

*Next: [Development Guide](../development/development-guide.md)*
