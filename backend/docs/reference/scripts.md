# Scripts Reference

Complete reference for all backend scripts and their usage.

## Operational Scripts

Located in `/scripts/backend/`

### build_and_deploy.sh

Builds Docker image and deploys to Google Cloud Run.

**Location:** `/scripts/backend/build_and_deploy.sh`

**Usage:**
```bash
./build_and_deploy.sh [--env=<environment>]
```

**Options:**
- `--env=dev` - Deploy to development (default)
- `--env=prod` - Deploy to production
- `--help` - Show usage information

**What it does:**
1. Authenticates with deployment service account
2. Creates Artifact Registry repository (if needed)
3. Builds Docker image using Cloud Build
4. Pushes image to Artifact Registry
5. Deploys to Cloud Run with environment configuration
6. Configures GCS bucket CORS
7. Fixes signed URL generation

**Requirements:**
- `.env.dev` or `.env.prod` configured
- Deployment service account with proper roles
- `DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE` set

**Examples:**
```bash
# Deploy to development
./build_and_deploy.sh

# Deploy to production
./build_and_deploy.sh --env=prod
```

---

### run_docker_local.sh

Runs the backend API locally using Docker.

**Location:** `/scripts/backend/run_docker_local.sh`

**Usage:**
```bash
./run_docker_local.sh [--debug] [--env=<environment>]
```

**Options:**
- `--debug` - Enable remote debugging on port 5678
- `--env=dev` - Use development environment (default)
- `--env=local` - Use legacy local environment
- `--help` - Show usage information

**What it does:**
1. Loads environment variables from `.env.dev` or `.env.local`
2. Builds Docker image from backend directory
3. Configures GCS bucket CORS for local development
4. Runs container with port mapping (8000:8080)
5. Mounts service account key file

**Requirements:**
- `.env.dev` or `.env.local` configured
- `HOST_KEY_PATH` pointing to service account key
- Docker installed and running

**Examples:**
```bash
# Run normally
./run_docker_local.sh

# Run with debugger
./run_docker_local.sh --debug

# Use legacy local config
./run_docker_local.sh --env=local
```

**Accessing:**
- API: http://localhost:8000
- Swagger UI: http://localhost:8000/api/docs
- ReDoc: http://localhost:8000/api/redoc

---

## Setup Scripts

### setup-service-account.sh

Creates and configures the runtime service account for the backend API.

**Location:** `/scripts/backend/setup-service-account.sh`

**Usage:**
```bash
./setup-service-account.sh [project-id]
```

**Arguments:**
- `project-id` - GCP project ID (optional, uses current gcloud project if omitted)

**What it does:**
1. Enables required APIs (IAM, Storage, Firestore, Firebase)
2. Creates service account: `pottery-app-sa@{project-id}.iam.gserviceaccount.com`
3. Grants IAM roles:
   - Cloud Datastore User (Firestore)
   - Firebase Viewer (Auth)
   - Storage Admin (GCS + CORS)
   - Storage Object Admin (GCS objects)
4. Optionally creates service account key file

**Requirements:**
- Authenticated with gcloud (user account or deployment service account)
- Permissions to create service accounts and grant roles

**Examples:**
```bash
# Use current project
./setup-service-account.sh

# Specify project
./setup-service-account.sh pottery-app-prod
```

---

### setup-infrastructure.sh

Configures GCS bucket CORS settings for the specified environment.

**Location:** `/scripts/backend/setup-infrastructure.sh`

**Usage:**
```bash
./setup-infrastructure.sh <environment>
```

**Arguments:**
- `local` - Apply local development CORS (localhost origins)
- `prod` - Apply production CORS (specific domains)

**What it does:**
1. Loads environment variables from `.env.local` or `.env.prod`
2. Calls `manage-cors.sh` to apply CORS configuration
3. Uses configuration from `infrastructure/cors-config.<env>.json`

**Requirements:**
- `.env.local` or `.env.prod` with `GCS_BUCKET_NAME`
- Service account with Storage Admin role

**Examples:**
```bash
# Local development
./setup-infrastructure.sh local

# Production
./setup-infrastructure.sh prod
```

---

### manage-cors.sh

Low-level CORS management tool.

**Location:** `/scripts/backend/manage-cors.sh`

**Usage:**
```bash
./manage-cors.sh <action> [environment] [bucket]
```

**Actions:**
- `apply` - Apply CORS configuration
- `status` - Show current CORS settings
- `remove` - Remove all CORS rules

**Examples:**
```bash
# Apply local CORS
./manage-cors.sh apply local

# Check current CORS
./manage-cors.sh status

# Apply to specific bucket
./manage-cors.sh apply prod my-custom-bucket
```

**CORS Configuration Files:**
- `infrastructure/cors-config.local.json` - Localhost origins, 5-minute cache
- `infrastructure/cors-config.prod.json` - Production domains, 1-hour cache
- `infrastructure/cors-config.json` - Default/testing (wildcard)

---

## Wrapper Scripts

Convenience scripts that call the main operational scripts with pre-configured settings.

### deploy-dev.sh

**Location:** `/scripts/backend/deploy-dev.sh`

Quick deploy to development environment.

```bash
./deploy-dev.sh
```

Equivalent to: `./build_and_deploy.sh --env=dev`

---

### deploy-prod.sh

**Location:** `/scripts/backend/deploy-prod.sh`

Deploy to production with confirmation prompt.

```bash
./deploy-prod.sh
```

Prompts for confirmation, then runs: `./build_and_deploy.sh --env=prod`

---

### deploy-local.sh

**Location:** `/scripts/backend/deploy-local.sh`

Run backend locally with Docker.

```bash
./deploy-local.sh
```

Equivalent to: `./run_docker_local.sh`

---

## Support Scripts

### fix-signed-urls.sh

Configures signed URL generation for Cloud Run environment.

**Location:** `/scripts/backend/fix-signed-urls.sh`

**Usage:**
```bash
./fix-signed-urls.sh --env=<environment>
```

**What it does:**
Ensures Cloud Run service can generate signed URLs by configuring service account impersonation.

**Note:** Called automatically by `build_and_deploy.sh`

---

### test-cors.sh

Tests CORS configuration for a bucket.

**Location:** `/scripts/backend/test-cors.sh`

**Usage:**
```bash
./test-cors.sh [bucket] [origin]
```

**Examples:**
```bash
# Test with defaults
./test-cors.sh

# Test specific bucket/origin
./test-cors.sh my-bucket http://localhost:3000
```

---

## Legacy Scripts

### setup-firebase-complete.sh

**Location:** `/scripts/backend/setup-firebase-complete.sh`

Comprehensive Firebase project setup script. Used for initial project creation.

**Status:** Maintained for backward compatibility. For new projects, use the individual setup scripts above.

---

## Script Locations Summary

```
scripts/
└── backend/
    ├── build_and_deploy.sh          # Main deployment script
    ├── run_docker_local.sh           # Local Docker runtime
    ├── setup-service-account.sh      # Create runtime SA
    ├── setup-infrastructure.sh       # Setup infrastructure
    ├── manage-cors.sh                # CORS management
    ├── deploy-dev.sh                 # Deploy to dev (wrapper)
    ├── deploy-prod.sh                # Deploy to prod (wrapper)
    ├── deploy-local.sh               # Run locally (wrapper)
    ├── fix-signed-urls.sh            # Fix signed URLs
    ├── test-cors.sh                  # Test CORS
    └── setup-firebase-complete.sh    # Legacy Firebase setup
```

## Environment Files

Scripts load configuration from:
- `backend/.env.local` - Local Docker development
- `backend/.env.dev` - Development environment
- `backend/.env.prod` - Production environment
- `backend/.env.test` - Integration testing

See [Environment Variables Reference](environment-variables.md) for complete variable documentation.

## Common Workflows

### Initial Setup
```bash
# 1. Create service accounts
./setup-service-account.sh your-project

# 2. Configure environment
# Edit backend/.env.dev or backend/.env.prod

# 3. Setup infrastructure
./setup-infrastructure.sh local  # or prod
```

### Development Workflow
```bash
# Run locally
./run_docker_local.sh

# Make changes
# ...

# Test
cd ../backend && pytest

# Deploy to dev
cd ../scripts/backend
./build_and_deploy.sh --env=dev
```

### Production Deployment
```bash
# Deploy to production
./build_and_deploy.sh --env=prod

# Or use wrapper with confirmation
./deploy-prod.sh
```

## Troubleshooting

### Script Not Found Errors

Ensure you're in the correct directory:
```bash
cd /path/to/pottery-backend/scripts/backend
```

### Permission Denied

Make scripts executable:
```bash
chmod +x *.sh
```

### Authentication Errors

Check your gcloud authentication:
```bash
gcloud auth list
gcloud config get-value project
```

### Path Issues

All scripts now use absolute path calculations and work from any location. If you encounter path errors, ensure you're running the latest version of the scripts.

## Related Documentation

- [Environment Variables Reference](environment-variables.md)
- [Production Setup Guide](../how-to/setup-production.md)
- [Local Development Guide](../getting-started/local-development.md)
- [Troubleshooting Guide](../how-to/troubleshoot-common-issues.md)
