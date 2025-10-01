#!/bin/bash

# Development Environment Build Script
# Builds Flutter app for development environment with local or dev backend
# Creates separate apps: "Pottery Studio Local" and "Pottery Studio Dev"

set -e

echo "🚀 Building Flutter app for DEVELOPMENT environment..."

# App flavor and backend selection function
select_flavor_and_backend() {
  # Skip selection if both are already set via environment variables
  if [ -n "$FLAVOR" ] && [ -n "$API_BASE_URL" ]; then
    echo "ℹ️  Using FLAVOR from environment: $FLAVOR"
    echo "ℹ️  Using API_BASE_URL from environment: $API_BASE_URL"
    return
  fi

  # Auto-detect local IP address
  LOCAL_IP=$(ifconfig en0 2>/dev/null | grep inet | grep -v inet6 | awk '{print $2}' | head -1)
  if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP=$(ifconfig wlan0 2>/dev/null | grep inet | grep -v inet6 | awk '{print $2}' | head -1)
  fi
  if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP="localhost"
  fi

  echo ""
  echo "🎯 Select app flavor and backend:"
  echo "1) Pottery Studio Local (http://$LOCAL_IP:8000) - Local Docker backend"
  echo "2) Pottery Studio Dev (https://pottery-api-dev.run.app) - Google Cloud Run dev"
  echo "3) Custom configuration (manual entry)"
  echo ""

  while true; do
    read -p "Choose configuration [1-3]: " choice
    case $choice in
      1)
        FLAVOR="local"
        API_BASE_URL="http://$LOCAL_IP:8000"
        APP_NAME="Pottery Studio Local"
        echo "✅ Selected: $APP_NAME with Local Docker backend"
        break
        ;;
      2)
        FLAVOR="dev"
        API_BASE_URL="https://pottery-api-dev-1073709451179.us-central1.run.app"
        APP_NAME="Pottery Studio Dev"
        echo "✅ Selected: $APP_NAME with Google Cloud Run dev"
        break
        ;;
      3)
        read -p "Enter flavor (local/dev): " FLAVOR
        read -p "Enter API base URL: " API_BASE_URL
        case $FLAVOR in
          local) APP_NAME="Pottery Studio Local" ;;
          dev) APP_NAME="Pottery Studio Dev" ;;
          *) echo "❌ Invalid flavor. Using dev."; FLAVOR="dev"; APP_NAME="Pottery Studio Dev" ;;
        esac
        echo "✅ Selected: Custom configuration ($APP_NAME with $API_BASE_URL)"
        break
        ;;
      *)
        echo "❌ Invalid choice. Please select 1, 2, or 3."
        ;;
    esac
  done
  echo ""
}

# Build configuration
ENVIRONMENT="development"
DEBUG_ENABLED="true"
CLEAN_INSTALL="${CLEAN_INSTALL:-false}"

# Select flavor and backend interactively
select_flavor_and_backend

echo "📋 Build Configuration:"
echo "   Environment: $ENVIRONMENT"
echo "   Flavor: $FLAVOR"
echo "   App Name: $APP_NAME"
echo "   API Base URL: $API_BASE_URL"
echo "   Debug Enabled: $DEBUG_ENABLED"
echo "   Clean Install: $CLEAN_INSTALL"
echo ""

# Clean install function
cleanup_old_app() {
  if [ "$CLEAN_INSTALL" = "true" ]; then
    echo "🧹 Uninstalling old app versions..."
    # Try to uninstall all possible package names
    adb uninstall com.example.pottery_frontend 2>/dev/null || true
    adb uninstall com.pottery.app 2>/dev/null || true
    adb uninstall com.pottery.app.local 2>/dev/null || true
    adb uninstall com.pottery.app.dev 2>/dev/null || true
    echo "✅ Cleanup completed"
    echo ""
  fi
}

# Build for different platforms
case "${1:-debug}" in
  "debug"|"")
    echo "🔨 Building debug version for development..."
    cleanup_old_app
    flutter run \
      --flavor $FLAVOR \
      --dart-define=ENVIRONMENT=$ENVIRONMENT \
      --dart-define=API_BASE_URL=$API_BASE_URL \
      --dart-define=DEBUG_ENABLED=$DEBUG_ENABLED
    ;;

  "release")
    echo "🔨 Building release APK for development testing..."
    flutter build apk \
      --flavor $FLAVOR \
      --dart-define=ENVIRONMENT=$ENVIRONMENT \
      --dart-define=API_BASE_URL=$API_BASE_URL \
      --dart-define=DEBUG_ENABLED=$DEBUG_ENABLED
    ;;

  "appbundle"|"aab")
    echo "🔨 Building AAB for Play Store (development)..."

    # Opening move: read current version from pubspec.yaml
    PUBSPEC_PATH="$(dirname "$(dirname "${BASH_SOURCE[0]}")")/pubspec.yaml"
    CURRENT_VERSION=$(grep "^version:" "$PUBSPEC_PATH" | sed 's/version: //')
    BUILD_NAME=$(echo $CURRENT_VERSION | cut -d'+' -f1)
    BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)

    # Main play: increment build number and patch version
    NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
    MAJOR=$(echo $BUILD_NAME | cut -d'.' -f1)
    MINOR=$(echo $BUILD_NAME | cut -d'.' -f2)
    PATCH=$(echo $BUILD_NAME | cut -d'.' -f3)
    NEW_PATCH=$((PATCH + 1))
    NEW_BUILD_NAME="$MAJOR.$MINOR.$NEW_PATCH"

    echo "📋 Version Information:"
    echo "   Current: $BUILD_NAME+$BUILD_NUMBER"
    echo "   New:     $NEW_BUILD_NAME+$NEW_BUILD_NUMBER"
    echo ""

    # Update pubspec.yaml with new version
    sed -i '' "s/^version: .*/version: $NEW_BUILD_NAME+$NEW_BUILD_NUMBER/" "$PUBSPEC_PATH"
    echo "✅ Updated pubspec.yaml to version $NEW_BUILD_NAME+$NEW_BUILD_NUMBER"
    echo ""

    # Victory lap: build the AAB with the new version
    flutter build appbundle \
      --release \
      --flavor $FLAVOR \
      --dart-define=ENVIRONMENT=$ENVIRONMENT \
      --dart-define=API_BASE_URL=$API_BASE_URL \
      --dart-define=DEBUG_ENABLED=$DEBUG_ENABLED \
      --build-name=$NEW_BUILD_NAME \
      --build-number=$NEW_BUILD_NUMBER

    echo ""
    echo "📦 AAB Location: build/app/outputs/bundle/${FLAVOR}Release/app-${FLAVOR}-release.aab"
    echo "🎯 Ready for Play Store upload!"
    ;;

  "ios")
    echo "🔨 Building iOS version for development..."
    flutter build ios \
      --dart-define=ENVIRONMENT=$ENVIRONMENT \
      --dart-define=API_BASE_URL=$API_BASE_URL \
      --dart-define=DEBUG_ENABLED=$DEBUG_ENABLED
    ;;

  "macos")
    echo "🔨 Building macOS version for development..."
    flutter build macos \
      --dart-define=ENVIRONMENT=$ENVIRONMENT \
      --dart-define=API_BASE_URL=$API_BASE_URL \
      --dart-define=DEBUG_ENABLED=$DEBUG_ENABLED
    ;;

  "web")
    echo "🔨 Building web version for development..."
    flutter build web \
      --dart-define=ENVIRONMENT=$ENVIRONMENT \
      --dart-define=API_BASE_URL=$API_BASE_URL \
      --dart-define=DEBUG_ENABLED=$DEBUG_ENABLED
    ;;

  "help"|"-h"|"--help")
    echo "Usage: $0 [platform]"
    echo ""
    echo "Platforms:"
    echo "  debug     Run in debug mode (default)"
    echo "  release   Build Android APK"
    echo "  appbundle Build AAB for Play Store (auto-increments version)"
    echo "  aab       Alias for appbundle"
    echo "  ios       Build iOS app"
    echo "  macos     Build macOS app"
    echo "  web       Build web app"
    echo "  help      Show this help"
    echo ""
    echo "Environment Variables:"
    echo "  API_BASE_URL    Override API base URL (default: http://localhost:8000)"
    echo "  CLEAN_INSTALL   Uninstall old app before installing (default: false)"
    echo "  FLAVOR          Set flavor (local/dev) - skips interactive selection"
    echo ""
    echo "Examples:"
    echo "  $0                              # Run in debug mode"
    echo "  $0 release                      # Build Android APK"
    echo "  $0 appbundle                    # Build AAB for Play Store"
    echo "  FLAVOR=dev $0 aab               # Build dev AAB (non-interactive)"
    echo "  API_BASE_URL=https://dev.pottery.com $0 web  # Build web with custom API"
    echo "  CLEAN_INSTALL=true $0           # Uninstall old app and run clean"
    exit 0
    ;;

  *)
    echo "❌ Unknown platform: $1"
    echo "Use '$0 help' for usage information"
    exit 1
    ;;
esac

echo ""
echo "✅ Development build completed!"
echo "🌍 Environment: $ENVIRONMENT"
echo "🔗 API URL: $API_BASE_URL"
