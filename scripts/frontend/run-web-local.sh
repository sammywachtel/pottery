#!/bin/bash

# Run Flutter Web with Local Docker Backend
# This script runs the Flutter web app on port 9102 (authorized in Firebase)
# and connects to LOCAL Docker backend at localhost:8000

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

cd "$FRONTEND_DIR"

# Configuration
PORT="${WEB_PORT:-9102}"
BACKEND_URL="http://localhost:8000"
ENVIRONMENT="development"
DEBUG_ENABLED="true"

echo "🚀 Starting Flutter Web Application (LOCAL BACKEND)"
echo "===================================================="
echo ""
echo "📋 Configuration:"
echo "   Web Port: $PORT"
echo "   Backend: LOCAL Docker (http://localhost:8000)"
echo "   Environment: $ENVIRONMENT"
echo "   Debug: $DEBUG_ENABLED"
echo ""
echo "⚠️  Make sure local Docker backend is running:"
echo "   cd backend && ./run_docker_local.sh"
echo ""
echo "🌐 Access the app at: http://localhost:$PORT"
echo "🔑 Google Sign-In will work (port $PORT is authorized)"
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
