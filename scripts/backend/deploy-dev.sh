#!/bin/bash

# Backend Development Cloud Run Deployment Script
# Deploys backend to Google Cloud Run (development environment)
# Points to: https://pottery-api-dev-1073709451179.us-central1.run.app

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
CONFIG_DIR="$SCRIPT_DIR/../config"

echo "🚀 Deploying Backend to Development Cloud Run"
echo "=============================================="

# Load environment configuration
source "$CONFIG_DIR/env.dev.sh"

# Navigate to backend directory
cd "$BACKEND_DIR"

# Deploy to Cloud Run
./build_and_deploy.sh --env=dev

echo "✅ Backend deployed to: https://pottery-api-dev-1073709451179.us-central1.run.app"
echo "📋 View logs: gcloud run services logs read pottery-api-dev --region=us-central1"
