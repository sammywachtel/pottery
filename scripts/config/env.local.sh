#!/bin/bash

# Local Environment Configuration
# Environment: Local Docker Development
# Backend URL: http://localhost:8000
# Frontend App: Pottery Studio Local (com.pottery.app.local)

export ENVIRONMENT="local"
export BACKEND_URL="http://localhost:8000"
export FRONTEND_PACKAGE="com.pottery.app.local"
export FRONTEND_APP_NAME="Pottery Studio Local"

# Google Cloud Configuration
export GCP_PROJECT_ID="pottery-app-456522"
export GCS_BUCKET_NAME="pottery-app-dev-456522-1759003953"
export FIRESTORE_COLLECTION="pottery_items"
export FIRESTORE_DATABASE_ID="(default)"

# Firebase Configuration
export FIREBASE_PROJECT_ID="pottery-app-456522"
export FIREBASE_AUTH_DOMAIN="pottery-app-456522.firebaseapp.com"

# Service Account (for local development)
export HOST_KEY_PATH="$HOME/.gsutil/pottery-app-sa-456522-6fd91fa85ea6.json"

# Local Docker Configuration
export DOCKER_IMAGE_NAME="pottery-api-local-image"
export DOCKER_CONTAINER_NAME="pottery-backend"
export LOCAL_PORT="8000"
export CONTAINER_PORT="8080"
export DEBUG_PORT="5678"

echo "✅ Loaded LOCAL environment configuration"
