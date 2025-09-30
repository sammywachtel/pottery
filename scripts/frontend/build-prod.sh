#!/bin/bash

# Frontend Build Script - Production Backend
# Builds Flutter app pointing to Google Cloud Run production environment
# App Name: Pottery Studio
# Backend: https://pottery-api-prod.run.app

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
CONFIG_DIR="$SCRIPT_DIR/../config"

echo "📱 Building Frontend for Production Backend"
echo "==========================================="
echo "⚠️  WARNING: This builds the PRODUCTION app!"
echo ""

echo "📋 Build Configuration:"
echo "   App Name: Pottery Studio"
echo "   Package: com.pottery.app"
echo "   Backend: https://pottery-api-prod.run.app"
echo ""

# Navigate to frontend directory
cd "$FRONTEND_DIR"

# Clean previous builds
flutter clean

# Build the production app
./scripts/build_prod.sh

echo "✅ App installed: Pottery Studio (Production)"
echo "🔗 Connects to: https://pottery-api-prod.run.app"
