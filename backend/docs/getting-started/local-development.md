# Local Development Quick Start

Get the Pottery API running locally in under 10 minutes.

## Prerequisites

- Python 3.10+
- Docker Desktop installed and running
- Google Cloud SDK (`gcloud`) installed
- Access to a GCP project with Firestore and Cloud Storage

## Quick Start (3 Steps)

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.local.example .env.local

# Edit .env.local with your settings
# Minimum required:
# - GCP_PROJECT_ID
# - GCS_BUCKET_NAME
# - HOST_KEY_PATH (path to service account key)
# - FIREBASE_PROJECT_ID
```

### 3. Run with Docker

```bash
# From the scripts/backend directory
cd ../scripts/backend
./run_docker_local.sh
```

The API will be available at:
- **API:** http://localhost:8000
- **Swagger UI:** http://localhost:8000/api/docs
- **ReDoc:** http://localhost:8000/api/redoc

---

## Alternative: Run Without Docker

For faster iteration without Docker overhead:

```bash
cd backend
export $(cat .env.local | xargs)
python main.py
```

---

## Development Workflows

### Running Tests

```bash
cd backend

# Run unit tests only (fast, no GCP needed)
pytest -m "not integration"

# Run with coverage
pytest --cov=. --cov-report=html -m "not integration"

# Run integration tests (requires test GCP project)
pytest -m integration

# Run all tests
pytest
```

### Debug Mode (PyCharm)

```bash
# Start with debug mode enabled
./run_docker_local.sh --debug
```

Then configure PyCharm remote debugger:
- Host: `localhost`
- Port: `5678`
- Path mapping: `/Users/your-path/backend` → `/app`

### Code Quality

Pre-commit hooks run automatically. To run manually:

```bash
cd backend
pre-commit run --all-files
```

Quality checks include:
- Black (code formatting)
- isort (import sorting)
- flake8 (linting)
- mypy (type checking)
- detect-secrets (security)

---

## Environment Setup Details

### Service Account Key

You need a service account key for local development:

#### Option A: Use Existing Service Account

```bash
# Download key for existing service account
gcloud iam service-accounts keys create ~/.gsutil/pottery-dev-key.json \
  --iam-account=pottery-app-sa@your-project.iam.gserviceaccount.com
```

#### Option B: Create New Service Account

```bash
# Navigate to scripts directory
cd ../scripts/backend

# Run setup script
./setup-service-account.sh your-project-id

# When prompted, create a key file
```

Update `.env.local`:
```bash
HOST_KEY_PATH=/Users/your-username/.gsutil/pottery-dev-key.json
```

### Firebase Configuration

Set up Firebase Authentication:

```bash
# In .env.local
FIREBASE_PROJECT_ID=your-firebase-project
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
```

### GCS Bucket

Ensure your GCS bucket exists and CORS is configured:

```bash
# Create bucket if needed
gcloud storage buckets create gs://your-dev-bucket \
  --project=your-project \
  --location=us-central1

# Configure CORS for local development
cd ../scripts/backend
./setup-infrastructure.sh local
```

---

## Common Tasks

### Viewing Logs

```bash
# Docker logs
docker logs pottery-backend

# Follow logs
docker logs -f pottery-backend
```

### Stopping the Server

```bash
# Stop Docker container
docker stop pottery-backend

# Remove container
docker rm pottery-backend
```

### Rebuilding After Changes

```bash
# Stop and rebuild
docker stop pottery-backend && docker rm pottery-backend
./run_docker_local.sh
```

### Testing API Endpoints

```bash
# Health check
curl http://localhost:8000/

# Get Firebase ID token from your app, then:
export TOKEN="your-firebase-id-token"

# List items
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/items

# Create item
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Pot","category":"bowl"}' \
  http://localhost:8000/api/items
```

---

## Troubleshooting

### Docker Build Fails

```bash
# Clear Docker cache
docker system prune -a

# Rebuild
./run_docker_local.sh
```

### Permission Denied on Service Account Key

```bash
# Fix permissions
chmod 600 ~/.gsutil/your-key-file.json
```

### Images Not Loading

```bash
# Verify CORS is configured
cd ../scripts/backend
./manage-cors.sh status

# Re-apply CORS
./setup-infrastructure.sh local
```

### Environment Variables Not Loading

```bash
# Check .env.local format (no quotes needed)
# Correct:   GCP_PROJECT_ID=my-project
# Incorrect: GCP_PROJECT_ID="my-project"

# Verify file exists
ls -la backend/.env.local
```

---

## Next Steps

- **Add Features:** Modify routers in `backend/routers/`
- **Update Models:** Edit Pydantic models in `backend/models.py`
- **Write Tests:** Add tests in `backend/tests/`
- **Deploy Changes:** See [Deployment Guide](../how-to/deploy-environments.md)

## Reference

- [Environment Variables Reference](../reference/environment-variables.md)
- [Scripts Reference](../reference/scripts.md)
- [Architecture Overview](../explanation/architecture.md)
