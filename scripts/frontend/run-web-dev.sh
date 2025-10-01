#!/bin/bash

# Run Flutter Web with Cloud Run Dev Backend
# This script runs the Flutter web app on port 9102 (authorized in Firebase)
# and connects to CLOUD RUN DEV backend

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

cd "$FRONTEND_DIR"

# Configuration
PORT="${WEB_PORT:-9102}"
BACKEND_URL="https://pottery-api-dev-1073709451179.us-central1.run.app"
ENVIRONMENT="development"
DEBUG_ENABLED="true"

echo "🚀 Starting Flutter Web Application (CLOUD RUN DEV BACKEND)"
echo "==========================================================="
echo ""
echo "📋 Configuration:"
echo "   Web Port: $PORT"
echo "   Backend: CLOUD RUN DEV"
echo "   Backend URL: $BACKEND_URL"
echo "   Environment: $ENVIRONMENT"
echo "   Debug: $DEBUG_ENABLED"
echo ""
echo "🌐 Access the app at: http://localhost:$PORT"
echo "🔑 Google Sign-In will work (port $PORT is authorized)"
echo "☁️  Using live Cloud Run dev backend (no local backend needed)"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Run Flutter web with fixed port
flutter run -d chrome \
  --web-hostname localhost \
  --web-port $PORT \
  --dart-define=API_BASE_URL=$BACKEND_URL \
  --dart-define=ENVIRONMENT=$ENVIRONMENT \
  --dart-define=DEBUG_ENABLED=$DEBUG_ENABLED
