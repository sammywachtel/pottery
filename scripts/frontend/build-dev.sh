#!/bin/bash

# Frontend Build Script - Development Backend
# Builds Flutter app pointing to Google Cloud Run dev environment
# App Name: Pottery Studio Dev
# Backend: https://pottery-api-dev-1073709451179.us-central1.run.app

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
CONFIG_DIR="$SCRIPT_DIR/../config"

echo "📱 Building Frontend for Development Backend"
echo "============================================"

echo "📋 Build Configuration:"
echo "   App Name: Pottery Studio Dev"
echo "   Package: com.pottery.app.dev"
echo "   Backend: https://pottery-api-dev-1073709451179.us-central1.run.app"
echo ""

# Navigate to frontend directory
cd "$FRONTEND_DIR"

# Clean previous builds
flutter clean

# Build and run the app
FLAVOR=dev \
API_BASE_URL="https://pottery-api-dev-1073709451179.us-central1.run.app" \
./scripts/build_dev.sh debug

echo "✅ App installed: Pottery Studio Dev"
echo "🔗 Connects to: https://pottery-api-dev-1073709451179.us-central1.run.app"
