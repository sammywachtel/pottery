#!/bin/bash

# Run Flutter Web Locally with Fixed Port
# This script runs the Flutter web app on port 9102 which is authorized in Firebase
# for Google OAuth authentication

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$FRONTEND_DIR"

# Configuration
PORT="${WEB_PORT:-9102}"
BACKEND_URL="${API_BASE_URL:-http://localhost:8000}"
ENVIRONMENT="development"
DEBUG_ENABLED="true"

echo "🚀 Starting Flutter Web Application"
echo "===================================="
echo ""
echo "📋 Configuration:"
echo "   Web Port: $PORT"
echo "   Backend URL: $BACKEND_URL"
echo "   Environment: $ENVIRONMENT"
echo "   Debug: $DEBUG_ENABLED"
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
