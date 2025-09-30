#!/bin/bash

# Production Environment Configuration
# Environment: Google Cloud Run Production
# Backend URL: https://pottery-api-prod.run.app
# Frontend App: Pottery Studio (com.pottery.app)

export ENVIRONMENT="production"
export BACKEND_URL="https://pottery-api-prod.run.app"
export FRONTEND_PACKAGE="com.pottery.app"
export FRONTEND_APP_NAME="Pottery Studio"

# Google Cloud Configuration
export GCP_PROJECT_ID="pottery-app-prod"
export GCS_BUCKET_NAME="pottery-app-prod-bucket"
export FIRESTORE_COLLECTION="pottery_items"
export FIRESTORE_DATABASE_ID="(default)"

# Firebase Configuration
export FIREBASE_PROJECT_ID="pottery-app-prod"
export FIREBASE_AUTH_DOMAIN="pottery-app-prod.firebaseapp.com"
export GOOGLE_CLOUD_PROJECT="pottery-app-prod"  # Required for Firebase in Cloud Run

# Cloud Run Configuration
export CLOUD_RUN_SERVICE_NAME="pottery-api-prod"
export CLOUD_RUN_REGION="us-central1"
export CLOUD_RUN_SERVICE_ACCOUNT="pottery-app-sa@pottery-app-prod.iam.gserviceaccount.com"
export DEPLOYMENT_SERVICE_ACCOUNT="pottery-app-install-sa@pottery-app-prod.iam.gserviceaccount.com"

# Artifact Registry
export ARTIFACT_REGISTRY_REPO="pottery-app-repo"
export IMAGE_URL="us-central1-docker.pkg.dev/pottery-app-prod/pottery-app-repo/pottery-api-prod:latest"

echo "✅ Loaded PRODUCTION environment configuration"
