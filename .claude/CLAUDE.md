# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Full-stack pottery catalog application:
- **backend/** - FastAPI application for managing pottery items with photos, using Google Cloud services (Firestore for metadata, Cloud Storage for photos)
- **frontend/** - Flutter mobile application (to be implemented)

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
# Navigate to backend directory
cd backend

# Run locally with Docker (reads .env.local)
./run_docker_local.sh

# Run in debug mode (PyCharm remote debugger on port 5678)
./run_docker_local.sh --debug

# Run without Docker (requires env vars)
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
# Navigate to backend directory
cd backend

# Deploy to Google Cloud Run (reads .env.deploy)
./build_and_deploy.sh
```

## Environment Configuration

Three separate `.env` files for different contexts:
- `.env.local` - Local Docker development
- `.env.test` - Test environment
- `.env.deploy` - Production deployment

Required variables:
- `GCP_PROJECT_ID` - Google Cloud project
- `GCS_BUCKET_NAME` - Storage bucket for photos
- `HOST_KEY_PATH` (local only) - Path to service account key
- `JWT_SECRET_KEY` - Secret for JWT signing

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
