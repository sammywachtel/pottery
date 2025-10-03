#!/bin/bash

# Fix Signed URL Generation in Cloud Run
# This script configures the Cloud Run service to use a service account key
# for generating signed URLs for Cloud Storage
# Usage: ./fix-signed-urls.sh [--env=<environment>]
# Environments: dev (default), prod

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"

# Opening move: parse environment argument
ENVIRONMENT="dev"  # Default to development
while [[ $# -gt 0 ]]; do
  case $1 in
    --env=*)
      ENVIRONMENT="${1#*=}"
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--env=<environment>]"
      echo "Environments: dev (default), prod"
      echo "Examples:"
      echo "  $0                # Fix dev environment"
      echo "  $0 --env=dev      # Fix dev environment"
      echo "  $0 --env=prod     # Fix production"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Main play: set environment-specific configuration and load env file
case $ENVIRONMENT in
  dev|development)
    echo "🔧 Fixing Signed URL Generation for DEVELOPMENT Cloud Run"
    ENV_FILE="${BACKEND_DIR}/.env.dev"
    ;;
  prod|production)
    echo "🔧 Fixing Signed URL Generation for PRODUCTION Cloud Run"
    ENV_FILE="${BACKEND_DIR}/.env.prod"
    ;;
  *)
    echo "Error: Invalid environment '$ENVIRONMENT'. Use 'dev' or 'prod'."
    exit 1
    ;;
esac

# Load environment variables
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file not found: $ENV_FILE"
    exit 1
fi

echo "Loading environment from: $ENV_FILE"
set -a  # Export all variables
source "$ENV_FILE"
set +a

echo "============================================="

# Configuration from environment
PROJECT_ID="${GCP_PROJECT_ID}"
SERVICE_NAME="${BUILD_SERVICE_NAME}"
SERVICE_ACCOUNT="pottery-app-sa@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="$HOME/.gsutil/pottery-app-sa-${PROJECT_ID}-key.json"

# Step 1: Check if service account key exists locally
if [ ! -f "$KEY_FILE" ]; then
    echo "📥 Creating service account key..."
    mkdir -p "$(dirname "$KEY_FILE")"
    gcloud iam service-accounts keys create "$KEY_FILE" \
        --iam-account="$SERVICE_ACCOUNT" \
        --project="$PROJECT_ID"
    echo "✅ Service account key created at: $KEY_FILE"
else
    echo "✅ Service account key already exists at: $KEY_FILE"
fi

# Step 2: Create a Secret Manager secret for the service account key
echo "🔐 Storing service account key in Secret Manager..."
SECRET_NAME="pottery-app-sa-key"

# Check if secret exists
if gcloud secrets describe $SECRET_NAME --project=$PROJECT_ID >/dev/null 2>&1; then
    echo "Secret $SECRET_NAME already exists, updating..."
    gcloud secrets versions add $SECRET_NAME \
        --data-file="$KEY_FILE" \
        --project=$PROJECT_ID
else
    echo "Creating new secret $SECRET_NAME..."
    gcloud secrets create $SECRET_NAME \
        --data-file="$KEY_FILE" \
        --replication-policy="automatic" \
        --project=$PROJECT_ID
fi

# Step 3: Grant Cloud Run service account access to the secret
echo "🔑 Granting Cloud Run access to the secret..."
gcloud secrets add-iam-policy-binding $SECRET_NAME \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/secretmanager.secretAccessor" \
    --project=$PROJECT_ID

# Step 4: Update Cloud Run service to mount the secret
echo "🚀 Updating Cloud Run service: $SERVICE_NAME..."

gcloud run services update $SERVICE_NAME \
    --region=us-central1 \
    --project=$PROJECT_ID \
    --update-secrets="/tmp/gcp_key.json=${SECRET_NAME}:latest" \
    --update-env-vars="GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp_key.json,FIREBASE_CREDENTIALS_FILE=/tmp/gcp_key.json"

echo ""
echo "✅ Signed URL generation fixed for $SERVICE_NAME ($ENVIRONMENT environment)!"
echo ""
echo "📋 What was done:"
echo "   1. Created/verified service account key"
echo "   2. Stored key in Secret Manager"
echo "   3. Mounted secret as file in Cloud Run container"
echo "   4. Set GOOGLE_APPLICATION_CREDENTIALS to point to the key"
echo ""
echo "🎉 Photos should now load properly in the app!"
