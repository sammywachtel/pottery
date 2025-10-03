# Scripts Reference

Complete reference for all scripts and utilities in the Pottery Catalog Application.

## 📁 Script Locations

### Infrastructure Scripts (`scripts/backend/`)

| Script | Purpose | Usage |
|--------|---------|-------|
| `setup-firebase-complete.sh` | Complete Firebase environment setup | `./setup-firebase-complete.sh` |
| `manage-cors.sh` | Cloud Storage CORS configuration | `./manage-cors.sh` |
| `setup-infrastructure.sh` | GCP infrastructure setup | `./setup-infrastructure.sh` |
| `test-cors.sh` | Test CORS configuration | `./test-cors.sh` |
| `run_migration.py` | Database migration utility | `python run_migration.py` |
| `setup_supabase_local.sh` | Local Supabase setup | `./setup_supabase_local.sh` |
| `deploy-dev.sh` | Deploy backend to Cloud Run dev | `./deploy-dev.sh` |
| `deploy-prod.sh` | Deploy backend to Cloud Run prod | `./deploy-prod.sh` |
| `deploy-local.sh` | Run backend locally with Docker | `./deploy-local.sh` |
| `fix-signed-urls.sh` | Fix signed URL configuration | `./fix-signed-urls.sh` |

### Frontend Scripts (`frontend/scripts/`)

| Script | Purpose | Usage |
|--------|---------|-------|
| `build_dev.sh` | Build Flutter app for development | `./build_dev.sh [debug\|release\|appbundle]` |
| `build_prod.sh` | Build Flutter app for production | `./build_prod.sh [android\|appbundle\|ios]` |
| `setup_firebase.sh` | Setup Firebase for Flutter | `./setup_firebase.sh` |

### Deployment Scripts (`backend/`)

| Script | Purpose | Usage |
|--------|---------|-------|
| `run_docker_local.sh` | Start local development backend | `./run_docker_local.sh [--debug]` |
| `build_and_deploy.sh` | Deploy backend to Cloud Run | `./build_and_deploy.sh` |

## 🚀 Development Scripts

### Local Development

#### `run_docker_local.sh`

**Purpose**: Start the backend in a Docker container for local development

**Usage**:
```bash
cd backend
./run_docker_local.sh [OPTIONS]
```

**Options**:
- `--debug`: Enable PyCharm remote debugger on port 5678
- `--rebuild`: Force rebuild of Docker image

**Environment**: Uses `.env.local` configuration file

**What it does**:
1. Loads environment variables from `.env.local`
2. Builds Docker image if needed
3. Mounts service account key file
4. Starts container with port mapping (8000:8080)
5. Optionally enables remote debugging

**Example**:
```bash
# Standard development
./run_docker_local.sh

# Debug mode for PyCharm
./run_docker_local.sh --debug

# Force rebuild and start
./run_docker_local.sh --rebuild
```

#### Flutter Development Commands

**Start Frontend**:
```bash
cd frontend
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --web-hostname localhost \
  --web-port 9100
```

**Build for Production**:
```bash
cd frontend
flutter build web \
  --dart-define=API_BASE_URL=https://your-production-url \
  --release
```

## 🏗️ Infrastructure Scripts

### `setup-firebase-complete.sh`

**Purpose**: Automated setup of complete Firebase environment with both dev and prod projects

**Location**: `scripts/backend/setup-firebase-complete.sh`

**Usage**:
```bash
cd scripts/backend
./setup-firebase-complete.sh
```

**What it creates**:
- New GCP project (pottery-app-prod)
- Firebase services enabled
- Web and Android app configurations
- Cloud Storage bucket with proper naming
- Firestore database
- OAuth client configuration
- Environment configuration files

**Output Files**:
- `.env.prod` - Production environment variables
- `firebase_config_prod.js` - Frontend configuration template
- `firestore.rules` - Database security rules
- `storage.rules` - Storage security rules

**Prerequisites**:
- Google Cloud CLI authenticated
- Firebase CLI installed and authenticated
- Billing account linked to projects

### `manage-cors.sh`

**Purpose**: Configure CORS settings for Cloud Storage buckets

**Location**: `scripts/backend/manage-cors.sh`

**Usage**:
```bash
cd scripts/backend
./manage-cors.sh [BUCKET_NAME]
```

**CORS Configuration**:
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"],
    "maxAgeSeconds": 3600
  }
]
```

**Operations**:
- Set CORS configuration
- Verify CORS settings
- Test CORS functionality

## 🚀 Deployment Scripts

### `build_and_deploy.sh`

**Purpose**: Complete backend deployment to Google Cloud Run

**Location**: `backend/build_and_deploy.sh`

**Usage**:
```bash
cd backend
./build_and_deploy.sh
```

**Environment**: Uses `.env.deploy` configuration file

**Deployment Process**:
1. Load environment variables from `.env.deploy`
2. Authenticate with deployment service account
3. Create Artifact Registry repository
4. Build Docker image
5. Push image to registry
6. Deploy to Cloud Run
7. Configure environment variables
8. Set IAM permissions

**Required Environment Variables**:
```bash
GCP_PROJECT_ID=pottery-app-prod
DEPLOYMENT_SERVICE_ACCOUNT_EMAIL=deploy-prod@pottery-app-prod.iam.gserviceaccount.com
DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE=/path/to/deploy-key.json
BUILD_SERVICE_NAME=pottery-api-prod
BUILD_REGION=us-central1
CLOUD_RUN_SERVICE_ACCOUNT_EMAIL=pottery-runtime-prod@pottery-app-prod.iam.gserviceaccount.com
```

**Cloud Run Configuration**:
- **CPU**: 2 vCPUs
- **Memory**: 2 GiB
- **Min Instances**: 1
- **Max Instances**: 100
- **Timeout**: 300 seconds
- **Concurrency**: 1000

## 🧪 Testing Scripts

### Backend Testing

**Unit Tests**:
```bash
cd backend
pytest -m "not integration"
```

**Integration Tests**:
```bash
cd backend
pytest -m integration
```

**Coverage Report**:
```bash
cd backend
pytest --cov=. --cov-report=html
```

**Specific Test Categories**:
```bash
# Authentication tests
pytest tests/test_auth.py

# API endpoint tests
pytest tests/test_items_router.py
pytest tests/test_photos_router.py

# Service layer tests
pytest tests/test_firestore_service.py
pytest tests/test_gcs_service.py
```

### Frontend Testing

**Unit Tests**:
```bash
cd frontend
flutter test
```

**Widget Tests**:
```bash
cd frontend
flutter test test/widget_test/
```

**Integration Tests**:
```bash
cd frontend
flutter drive --target=test_driver/app.dart
```

## 🔧 Utility Scripts

### Health Check Scripts

**Backend Health Check**:
```bash
#!/bin/bash
# Check if backend is responding
curl -f http://localhost:8000/ || exit 1
curl -f http://localhost:8000/api/docs || exit 1
echo "Backend health check passed"
```

**Production Health Check**:
```bash
#!/bin/bash
# Check production deployment
BACKEND_URL="https://pottery-api-prod-xxxxxxxx-uc.a.run.app"
curl -f $BACKEND_URL/ || exit 1
curl -f $BACKEND_URL/api/docs || exit 1
echo "Production health check passed"
```

### Database Management Scripts

**Firestore Backup**:
```bash
#!/bin/bash
gcloud firestore export gs://pottery-app-456522-backup/$(date +%Y%m%d) \
  --project=pottery-app-456522
```

**Firestore Restore**:
```bash
#!/bin/bash
# Restore from specific backup
gcloud firestore import gs://pottery-app-456522-backup/20240927 \
  --project=pottery-app-456522
```

### Development Convenience Scripts

**Reset Development Environment**:
```bash
#!/bin/bash
# Complete development environment reset
docker-compose down
docker system prune -f
cd frontend && flutter clean && flutter pub get
cd ../backend && ./run_docker_local.sh
```

**Start All Services**:
```bash
#!/bin/bash
# Start backend and frontend together
cd backend && ./run_docker_local.sh &
BACKEND_PID=$!
sleep 10  # Wait for backend to start
cd ../frontend && flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --web-hostname localhost \
  --web-port 9100 &
FRONTEND_PID=$!

echo "Backend PID: $BACKEND_PID"
echo "Frontend PID: $FRONTEND_PID"
echo "Backend: http://localhost:8000"
echo "Frontend: http://localhost:9100"
```

## 📊 Monitoring Scripts

### Log Collection

**Collect All Logs**:
```bash
#!/bin/bash
mkdir -p logs/$(date +%Y%m%d)
docker logs pottery-backend-container > logs/$(date +%Y%m%d)/backend.log
# Add Firebase logs, Cloud Run logs, etc.
```

**Parse Error Logs**:
```bash
#!/bin/bash
# Extract errors from logs
grep -i "error\|exception\|fail" logs/$(date +%Y%m%d)/backend.log > logs/$(date +%Y%m%d)/errors.log
```

### Performance Monitoring

**API Performance Test**:
```bash
#!/bin/bash
# Test API response times
echo "Testing API performance..."
for endpoint in "/" "/api/docs" "/api/items"; do
  echo "Testing $endpoint"
  curl -w "Time: %{time_total}s\n" -s http://localhost:8000$endpoint
done
```

**Memory Usage Monitor**:
```bash
#!/bin/bash
# Monitor container memory usage
while true; do
  docker stats pottery-backend-container --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
  sleep 30
done
```

## 🔐 Security Scripts

### Permission Auditing

**Check Service Account Permissions**:
```bash
#!/bin/bash
gcloud projects get-iam-policy pottery-app-456522 \
  --flatten="bindings[].members" \
  --filter="bindings.members:*pottery-app-sa*" \
  --format="table(bindings.role)"
```

**OAuth Client Audit**:
```bash
#!/bin/bash
# List OAuth clients
gcloud auth application-default print-access-token | \
xargs -I {} curl -H "Authorization: Bearer {}" \
  "https://www.googleapis.com/oauth2/v1/tokeninfo"
```

## 📋 Script Maintenance

### Script Updates

**Keep scripts executable**:
```bash
find . -name "*.sh" -exec chmod +x {} \;
```

**Validate shell scripts**:
```bash
# Install shellcheck
brew install shellcheck

# Check all scripts
find . -name "*.sh" -exec shellcheck {} \;
```

### Version Management

**Tag script versions**:
```bash
git tag -a scripts-v1.0 -m "Scripts version 1.0"
git push origin scripts-v1.0
```

**Script dependencies**:
Each script should include prerequisite checks:
```bash
#!/bin/bash
set -euo pipefail

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "Docker required but not installed"; exit 1; }
command -v gcloud >/dev/null 2>&1 || { echo "gcloud required but not installed"; exit 1; }
```

---

*Last updated: September 2025*
