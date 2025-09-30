#!/bin/bash

# Frontend Build Script - Local Backend
# Builds Flutter app pointing to local Docker backend
# App Name: Pottery Studio Local
# Backend: http://localhost:8000 (or your local IP)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
CONFIG_DIR="$SCRIPT_DIR/../config"

echo "📱 Building Frontend for Local Backend"
echo "======================================"

# Auto-detect local IP address
LOCAL_IP=$(ifconfig en0 2>/dev/null | grep inet | grep -v inet6 | awk '{print $2}' | head -1)
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP="localhost"
fi

echo "📋 Build Configuration:"
echo "   App Name: Pottery Studio Local"
echo "   Package: com.pottery.app.local"
echo "   Backend: http://$LOCAL_IP:8000"
echo ""

# Navigate to frontend directory
cd "$FRONTEND_DIR"

# Clean previous builds
flutter clean

# Build and run the app
FLAVOR=local \
API_BASE_URL="http://$LOCAL_IP:8000" \
./scripts/build_dev.sh debug

echo "✅ App installed: Pottery Studio Local"
echo "🔗 Connects to: http://$LOCAL_IP:8000"
