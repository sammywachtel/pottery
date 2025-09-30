#!/bin/bash

# Development Environment Configuration
# Environment: Google Cloud Run Development
# Backend URL: https://pottery-api-dev-1073709451179.us-central1.run.app
# Frontend App: Pottery Studio Dev (com.pottery.app.dev)

export ENVIRONMENT="development"
export BACKEND_URL="https://pottery-api-dev-1073709451179.us-central1.run.app"
export FRONTEND_PACKAGE="com.pottery.app.dev"
export FRONTEND_APP_NAME="Pottery Studio Dev"

# Google Cloud Configuration
export GCP_PROJECT_ID="pottery-app-456522"
export GCS_BUCKET_NAME="pottery-app-dev-456522-1759003953"
export FIRESTORE_COLLECTION="pottery_items"
export FIRESTORE_DATABASE_ID="(default)"

# Firebase Configuration
export FIREBASE_PROJECT_ID="pottery-app-456522"
export FIREBASE_AUTH_DOMAIN="pottery-app-456522.firebaseapp.com"
export GOOGLE_CLOUD_PROJECT="pottery-app-456522"  # Required for Firebase in Cloud Run

# Cloud Run Configuration
export CLOUD_RUN_SERVICE_NAME="pottery-api-dev"
export CLOUD_RUN_REGION="us-central1"
export CLOUD_RUN_SERVICE_ACCOUNT="pottery-app-sa@pottery-app-456522.iam.gserviceaccount.com"
export DEPLOYMENT_SERVICE_ACCOUNT="pottery-app-install-sa@pottery-app-456522.iam.gserviceaccount.com"

# Artifact Registry
export ARTIFACT_REGISTRY_REPO="pottery-app-repo"
export IMAGE_URL="us-central1-docker.pkg.dev/pottery-app-456522/pottery-app-repo/pottery-api-dev:latest"

echo "✅ Loaded DEVELOPMENT environment configuration"
