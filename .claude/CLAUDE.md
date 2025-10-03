# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Full-stack pottery catalog application:
- **backend/** - FastAPI application for managing pottery items with photos, using Google Cloud services (Firestore for metadata, Cloud Storage for photos)
- **frontend/** - Flutter application for web, iOS, Android, and macOS with multi-app build system

## Key Architecture

### Backend Service Layer Pattern
- **backend/routers/** - FastAPI route handlers (items.py, photos.py)
- **backend/services/** - Business logic and GCP interactions
  - `firestore_service.py` - Firestore CRUD operations
  - `gcs_service.py` - Cloud Storage operations and signed URL generation
- **backend/models.py** - Pydantic models with separate internal vs response schemas
- **backend/auth.py** - JWT authentication using OAuth2PasswordBearer

### Data Flow
1. Items stored in Firestore with embedded photo metadata
2. Photos stored in GCS at path: `items/{item_id}/{photo_id}.jpg`
3. Signed URLs generated on-demand for photo access (15 min expiration)
4. All data is user-scoped via JWT token authentication

## Development Commands

### Local Development
```bash
# Run locally with Docker
cd scripts/backend
./run_docker_local.sh

# Run in debug mode (PyCharm remote debugger on port 5678)
./run_docker_local.sh --debug

# Run with specific environment
./run_docker_local.sh --env=dev  # or --env=local

# Run without Docker (requires env vars)
cd backend
export $(cat .env.local | xargs)
python main.py
```

### Testing
```bash
# Navigate to backend directory
cd backend

# Run unit tests only (mocked services)
pytest -m "not integration"

# Run integration tests (requires test GCP project in .env.test)
pytest -m integration

# Run all tests
pytest

# Run specific test file
pytest tests/test_items_router.py

# Run with coverage
pytest --cov=. --cov-report=html
```

### Deployment
```bash
# Deploy to development
cd scripts/backend
./build_and_deploy.sh --env=dev

# Deploy to production
./build_and_deploy.sh --env=prod

# Or use wrapper scripts
./deploy-dev.sh   # Deploy to dev
./deploy-prod.sh  # Deploy to prod (with confirmation)
```

## Environment Configuration

Environment files are located in `backend/` directory:
- `.env.local` - Local Docker development (legacy)
- `.env.dev` - Development environment (default)
- `.env.prod` - Production environment
- `.env.test` - Integration testing

Required variables:
- `GCP_PROJECT_ID` - Google Cloud project
- `GCS_BUCKET_NAME` - Storage bucket for photos
- `HOST_KEY_PATH` (local only) - Path to service account key
- `FIREBASE_PROJECT_ID` - Firebase project for authentication
- `JWT_SECRET_KEY` - Secret for JWT signing (legacy, for backward compatibility)

## API Documentation

- Interactive docs: `http://localhost:8000/api/docs` (Swagger UI)
- Alternative docs: `http://localhost:8000/api/redoc`

## Authentication

Default dev credentials: `admin/admin`

All endpoints except `/` and `/api/token` require JWT authentication:
```bash
# Get token
curl -X POST "http://localhost:8000/api/token" \
  -d "username=admin&password=admin"

# Use token
curl -H "Authorization: Bearer {token}" \
  "http://localhost:8000/api/items"
```

## Key Implementation Details

### Photo Upload Flow
1. Upload photo via multipart/form-data to `/api/items/{item_id}/photos`
2. Photo stored in GCS at `items/{item_id}/{photo_id}.jpg`
3. Metadata embedded in item document in Firestore
4. Returns signed URL valid for 15 minutes

### User Data Isolation
- All items/photos are associated with authenticated user (`user_id` field)
- Users can only access their own data
- Admin users have access to all items

### Timestamp Handling
- All timestamps stored as UTC in backend
- Original timezone preserved in separate field (e.g., `createdTimezone`)
- Client responsible for timezone conversion for display

### Error Handling
- Global exception handlers for HTTPException, ValidationError, GoogleCloudError
- Structured error responses with proper HTTP status codes
- Detailed logging for debugging

## Documentation Structure

The backend documentation follows the **Diátaxis framework** for clear, use-case driven organization:

### Getting Started (Tutorials)
- **backend/docs/getting-started/local-development.md** - Quick start for local development
- Located in: `backend/docs/getting-started/`

### How-To Guides (Task-Oriented)
- **backend/docs/how-to/setup-production.md** - Complete production setup guide
- **backend/docs/how-to/deploy-environments.md** - Deploy to dev/prod environments
- **backend/docs/how-to/setup-service-accounts.md** - Service account creation
- **backend/docs/how-to/troubleshoot-common-issues.md** - Common problems and solutions
- Located in: `backend/docs/how-to/`

### Reference (Information-Oriented)
- **backend/docs/reference/scripts.md** - Complete scripts documentation
- **backend/docs/reference/environment-variables.md** - All configuration options
- **backend/docs/reference/api-endpoints.md** - API reference
- Located in: `backend/docs/reference/`

### Explanation (Understanding-Oriented)
- **backend/docs/explanation/architecture.md** - System design decisions
- **backend/docs/explanation/multi-environment.md** - Environment separation strategy
- **backend/docs/explanation/authentication.md** - Authentication flow and design
- Located in: `backend/docs/explanation/`

### Navigation Hub
- **backend/README.md** - Main entry point with "I want to..." navigation links

### Legacy Documentation
- **backend/README-old.md** - Archived original README
- **backend/README-environments-old.md** - Archived environment guide

**Finding Information:**
- Start with `backend/README.md` for navigation
- Use getting-started guides for first-time setup
- Use how-to guides for specific tasks
- Use reference docs to look up details
- Use explanation docs to understand why things work the way they do

## Frontend Documentation

The frontend documentation also follows the **Diátaxis framework** for use-case driven organization:

### Getting Started (Tutorials)
- **frontend/docs/getting-started/local-development.md** - Quick start for local Flutter development
- Located in: `frontend/docs/getting-started/`

### How-To Guides (Task-Oriented)
- **frontend/docs/how-to/build-and-deploy.md** - Build and deploy for all platforms and environments
- **frontend/docs/how-to/deploy-play-store.md** - Complete Google Play Store deployment guide
- **frontend/docs/how-to/troubleshooting.md** - Debug and fix common issues
- Located in: `frontend/docs/how-to/`

### Reference (Information-Oriented)
- **frontend/docs/reference/build-scripts.md** - Complete build scripts documentation
- Located in: `frontend/docs/reference/`

### Explanation (Understanding-Oriented)
- **frontend/docs/explanation/multi-app-system.md** - Multi-app build system architecture
- Located in: `frontend/docs/explanation/`

### Navigation Hub
- **frontend/README.md** - Main entry point with "I want to..." navigation links

### Legacy Documentation
- **frontend/README-old.md** - Archived original README
- **frontend/scripts/README-old.md** - Archived scripts README
- **frontend/scripts/README-multi-app-old.md** - Archived multi-app README

### Multi-App Build System
The frontend uses Android product flavors to create three independent app installations:
- **Pottery Studio Local** (`com.pottery.app.local`) - Local Docker backend
- **Pottery Studio Dev** (`com.pottery.app.dev`) - Cloud Run dev backend
- **Pottery Studio** (`com.pottery.app`) - Cloud Run prod backend

All three apps can coexist on the same device for efficient development and testing.

### Build Scripts Location
All frontend build scripts are in `frontend/scripts/`:
- `build_dev.sh` - Development builds (local or dev)
- `build_prod.sh` - Production builds
- `setup_firebase.sh` - Firebase configuration

**Finding Information:**
- Start with `frontend/README.md` for navigation
- Use getting-started guide for local development setup
- Use how-to guide for building and deploying
- Use reference docs for build script details
- Use explanation docs to understand the multi-app system
