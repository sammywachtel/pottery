#!/bin/bash

# Backend Production Cloud Run Deployment Script
# Deploys backend to Google Cloud Run (production environment)
# Points to: https://pottery-api-prod.run.app

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
CONFIG_DIR="$SCRIPT_DIR/../config"

echo "🚀 Deploying Backend to Production Cloud Run"
echo "============================================="
echo "⚠️  WARNING: This deploys to PRODUCTION!"
echo ""
read -p "Are you sure you want to deploy to production? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Deployment cancelled"
    exit 1
fi

# Load environment configuration
source "$CONFIG_DIR/env.prod.sh"

# Deploy to Cloud Run
"$SCRIPT_DIR/build_and_deploy.sh" --env=prod

echo "✅ Backend deployed to: https://pottery-api-prod.run.app"
echo "📋 View logs: gcloud run services logs read pottery-api-prod --region=us-central1"
