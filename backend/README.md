# Pottery Catalog API Backend

## Overview

FastAPI-based backend for managing pottery items with photos. Uses Google Cloud services (Firestore for metadata, Cloud Storage for photos) with JWT authentication and comprehensive quality gates.

## 🚀 Quick Start

### Prerequisites
- Python 3.10+
- Docker
- Google Cloud SDK (`gcloud`) installed and authenticated
- Access to Google Cloud Project with Firestore and Cloud Storage enabled

### Local Development Setup
```bash
# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Copy and configure environment files
cp .env.local.example .env.local
cp .env.test.example .env.test
cp .env.deploy.example .env.deploy

# Edit .env.local with your development settings
```

## 🧪 Testing & Development

### 1. Local Development (Docker)

**Standard Mode:**
```bash
./run_docker_local.sh
```
- Runs on `http://localhost:8000`
- Uses `.env.local` configuration
- Hot reload enabled

**Debug Mode (PyCharm Integration):**
```bash
./run_docker_local.sh --debug
```
- Exposes debugger port 5678
- Configure PyCharm remote debugger:
  - Host: localhost, Port: 5678
  - Path mapping: `/Users/your-path/backend` → `/app`

### 2. Local Development (Non-Docker)
```bash
# Ensure environment variables are set
export $(cat .env.local | xargs)
python main.py
```

### 3. Unit Testing
```bash
# Run unit tests only (mocked services)
pytest -m "not integration"

# Run with coverage
pytest --cov=. --cov-report=html -m "not integration"

# Run specific test file
pytest tests/test_items_router.py -v
```

### 4. Integration Testing (Real GCP Services)
```bash
# Requires .env.test with test GCP project
pytest -m integration

# Run all tests
pytest
```

## 🌐 Cloud Run Testing

### Deploy to Cloud Run for Testing
```bash
# Configure .env.deploy for your test environment
./build_and_deploy.sh
```

### Test Cloud Run Deployment
```bash
# Get your Cloud Run URL from deployment output
export CLOUD_RUN_URL="https://your-service-url.run.app"

# Test health endpoint
curl $CLOUD_RUN_URL/

# Test authentication
curl -X POST "$CLOUD_RUN_URL/api/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin"

# Test authenticated endpoint
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "$CLOUD_RUN_URL/api/items"
```

## 🚀 Multi-Environment Deployment

### Environment Configuration

| Environment | Purpose | Database | Configuration File |
|-------------|---------|----------|-------------------|
| **Local** | Development | Local Firestore Emulator* | `.env.local` |
| **Dev** | Development testing | GCP Project: `pottery-dev-*` | `.env.deploy.dev` |
| **Test** | Staging/QA | GCP Project: `pottery-test-*` | `.env.deploy.test` |
| **Production** | Live application | GCP Project: `pottery-prod-*` | `.env.deploy.prod` |

*\*Note: Firestore emulator setup coming in future release*

### Deployment Commands

**Development Environment:**
```bash
# Deploy to dev environment
cp .env.deploy.dev .env.deploy
./build_and_deploy.sh

# Set dev-specific Cloud Run service name
export BUILD_SERVICE_NAME="pottery-api-dev"
./build_and_deploy.sh
```

**Test Environment:**
```bash
# Deploy to test environment
cp .env.deploy.test .env.deploy
export BUILD_SERVICE_NAME="pottery-api-test"
./build_and_deploy.sh
```

**Production Environment:**
```bash
# Deploy to production (requires additional approval)
cp .env.deploy.prod .env.deploy
export BUILD_SERVICE_NAME="pottery-api-prod"
./build_and_deploy.sh
```

## 📊 Database Migration Planning

### Current: Google Cloud Firestore
- **Dev**: Firestore database in `pottery-dev-project`
- **Test**: Firestore database in `pottery-test-project`
- **Prod**: Firestore database in `pottery-prod-project`

### Future: Supabase Integration
*Planned migration to Supabase for better development experience and cost optimization:*

| Environment | Supabase Project | Database URL | Purpose |
|-------------|------------------|--------------|---------|
| **Dev** | `pottery-dev` | `postgresql://...dev.supabase.co` | Development testing |
| **Test** | `pottery-test` | `postgresql://...test.supabase.co` | QA and staging |
| **Prod** | `pottery-prod` | `postgresql://...prod.supabase.co` | Production data |

**Migration Benefits:**
- PostgreSQL relational database with better query capabilities
- Built-in authentication and authorization
- Real-time subscriptions
- Better local development with database branching
- Cost-effective scaling

## 🔧 Environment Variables

### Required Variables (All Environments)
```bash
# Google Cloud Configuration
GCP_PROJECT_ID=your-project-id
GCS_BUCKET_NAME=your-bucket-name

# Authentication
JWT_SECRET_KEY=your-secret-key-here
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30

# Database (Current: Firestore)
FIRESTORE_COLLECTION=pottery_items
FIRESTORE_DATABASE_ID=(default)

# Application
PORT=8080
SIGNED_URL_EXPIRATION_MINUTES=15
```

### Local Development Only
```bash
# Service account key for local development
HOST_KEY_PATH=/path/to/your/service-account-key.json
LOCAL_PORT=8000
DEBUG_PORT=5678
```

### Deployment Only
```bash
# Deployment configuration
DEPLOYMENT_SERVICE_ACCOUNT_EMAIL=deploy@your-project.iam.gserviceaccount.com
DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE=/path/to/deploy-key.json
BUILD_SERVICE_NAME=pottery-api
BUILD_REGION=us-central1
CLOUD_RUN_SERVICE_ACCOUNT_EMAIL=runtime@your-project.iam.gserviceaccount.com
```

## 📋 API Documentation

### Interactive Documentation
- **Swagger UI**: `http://localhost:8000/api/docs`
- **ReDoc**: `http://localhost:8000/api/redoc`

### Authentication
Default development credentials:
- Username: `admin`
- Password: `admin`

**Get Token:**
```bash
curl -X POST "http://localhost:8000/api/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin"
```

**Use Token:**
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://localhost:8000/api/items"
```

## 🛠️ Development Workflow

### Quality Gates
This project uses comprehensive pre-commit hooks:
```bash
# Install hooks (done automatically during setup)
pre-commit install

# Run manually
pre-commit run --all-files
```

### Code Standards
- **Line Length**: 88 characters (Black formatter)
- **Import Sorting**: isort
- **Linting**: flake8
- **Type Checking**: mypy
- **Security**: detect-secrets

### Making Changes
1. Create feature branch from `main`
2. Make changes (quality gates run on commit)
3. Run tests: `pytest -m "not integration"`
4. Create pull request
5. Deploy to dev environment for testing
6. Merge after review and testing

## 🏗️ Infrastructure Management

### CORS Configuration for GCS Bucket

The application automatically manages Google Cloud Storage (GCS) bucket CORS configuration to enable Flutter web apps and other browser clients to display images.

**Quick Setup:**
```bash
# Local development CORS
./scripts/manage-cors.sh apply local

# Production CORS
./scripts/manage-cors.sh apply prod

# Check current CORS settings
./scripts/manage-cors.sh status
```

**Automatic Integration:**
- `./run_docker_local.sh` - Automatically applies local CORS config
- `./build_and_deploy.sh` - Automatically applies production CORS config
- `npm run infra:setup` - Manual infrastructure setup

**Configuration Files:**
- `infrastructure/cors-config.local.json` - Local development (localhost origins)
- `infrastructure/cors-config.prod.json` - Production (specific domains)
- `infrastructure/cors-config.json` - Default/testing (permissive)

**Testing CORS:**
```bash
# Test CORS configuration
./scripts/test-cors.sh

# Test specific bucket/origin
./scripts/test-cors.sh my-bucket http://localhost:3000
```

**Available NPM Scripts:**
```bash
npm run infra:setup           # Full infrastructure setup
npm run infra:cors:local      # Apply local CORS config
npm run infra:cors:prod       # Apply production CORS config
npm run infra:cors:status     # Check current CORS config
npm run infra:cors:remove     # Remove all CORS rules
```

**Troubleshooting CORS Issues:**
1. **Images not loading in Flutter app:**
   - Check browser console for CORS errors
   - Verify CORS applied: `./scripts/manage-cors.sh status`
   - Clear browser cache (Ctrl+F5 or incognito mode)
   - Test with: `./scripts/test-cors.sh`

2. **Wrong origin errors:**
   - Update `infrastructure/cors-config.*.json` files
   - Reapply config: `./scripts/manage-cors.sh apply [environment]`
   - Wait 2-5 minutes for changes to propagate

3. **Authentication errors:**
   - Ensure gcloud is authenticated: `gcloud auth login`
   - Check project: `gcloud config get-value project`
   - Verify bucket permissions: `gsutil iam get gs://your-bucket`

See `infrastructure/README.md` for complete documentation.

## 🔍 Troubleshooting

### Common Issues

**Docker Build Fails:**
```bash
# Clear Docker cache
docker system prune -a
./run_docker_local.sh
```

**Tests Fail:**
```bash
# Check environment variables
python -c "from config import settings; print(settings.gcp_project_id)"

# Verify GCP authentication
gcloud auth application-default print-access-token
```

**Cloud Run Deployment Fails:**
```bash
# Check deployment service account permissions
gcloud projects get-iam-policy $GCP_PROJECT_ID

# Verify Artifact Registry exists
gcloud artifacts repositories list --location=$BUILD_REGION
```

### Debug Logs
```bash
# Local container logs
docker logs pottery-api-local-image

# Cloud Run logs
gcloud logging read "resource.type=cloud_run_revision" --limit=50
```

## 📁 Project Structure

```
backend/
├── routers/            # FastAPI route handlers
│   ├── items.py       # Pottery items endpoints
│   └── photos.py      # Photo management endpoints
├── services/          # Business logic layer
│   ├── firestore_service.py  # Database operations
│   └── gcs_service.py        # Cloud Storage operations
├── tests/             # Test suite
│   ├── integration/   # Integration tests (require GCP)
│   └── images/       # Test image files
├── main.py           # FastAPI application entry point
├── models.py         # Pydantic data models
├── auth.py          # JWT authentication
├── config.py        # Application configuration
└── Dockerfile       # Container definition
```

## 🔄 Future Enhancements

### Planned Database Migration
- [ ] **Supabase Integration**: Migrate from Firestore to PostgreSQL
- [ ] **Multi-environment Databases**: Separate dev/test/prod databases
- [ ] **Database Migrations**: Automated schema versioning
- [ ] **Local Database**: Supabase local development setup

### Deployment Improvements
- [ ] **CI/CD Pipeline**: Automated testing and deployment
- [ ] **Environment Promotion**: Dev → Test → Prod workflow
- [ ] **Blue/Green Deployments**: Zero-downtime deployments
- [ ] **Health Checks**: Comprehensive monitoring and alerting

### Development Experience
- [ ] **Firestore Emulator**: Local development without GCP
- [ ] **Hot Reload**: Faster development iteration
- [ ] **Performance Monitoring**: APM integration
- [ ] **Load Testing**: Automated performance testing
