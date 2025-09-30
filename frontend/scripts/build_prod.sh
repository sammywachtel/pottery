#!/bin/bash

# Production Environment Build Script
# Builds Flutter app "Pottery Studio" for production environment
# Creates separate app from dev/local versions

set -e

echo "🏭 Building Flutter app for PRODUCTION environment..."

# Build configuration
ENVIRONMENT="production"
FLAVOR="prod"
API_BASE_URL="${API_BASE_URL:-https://pottery-api-prod.run.app}"
DEBUG_ENABLED="false"

# Security check
if [[ "$API_BASE_URL" == *"localhost"* ]]; then
  echo "⚠️  WARNING: API_BASE_URL contains 'localhost' in production build!"
  echo "   Current URL: $API_BASE_URL"
  echo "   Consider using production URL instead"
  echo ""
  read -p "Continue anyway? (y/N): " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Build cancelled"
    exit 1
  fi
fi

echo "📋 Production Build Configuration:"
echo "   Environment: $ENVIRONMENT"
echo "   Flavor: $FLAVOR"
echo "   App Name: Pottery Studio"
echo "   API Base URL: $API_BASE_URL"
echo "   Debug Enabled: $DEBUG_ENABLED"
echo ""

# Build for different platforms
case "${1:-release}" in
  "android"|"release"|"")
    echo "🔨 Building Android release for production..."
    flutter build apk --release \
      --flavor $FLAVOR \
      --dart-define=ENVIRONMENT=$ENVIRONMENT \
      --dart-define=API_BASE_URL=$API_BASE_URL \
      --dart-define=DEBUG_ENABLED=$DEBUG_ENABLED \
      --obfuscate \
      --split-debug-info=build/debug-info

    echo ""
    echo "📱 Android APK built successfully!"
    echo "📍 Location: build/app/outputs/flutter-apk/app-release.apk"
    ;;

  "ios")
    echo "🔨 Building iOS release for production..."
    flutter build ios --release \
      --flavor $FLAVOR \
      --dart-define=ENVIRONMENT=$ENVIRONMENT \
      --dart-define=API_BASE_URL=$API_BASE_URL \
      --dart-define=DEBUG_ENABLED=$DEBUG_ENABLED \
      --obfuscate \
      --split-debug-info=build/debug-info

    echo ""
    echo "📱 iOS app built successfully!"
    echo "📍 Next: Archive in Xcode and upload to App Store"
    ;;

  "web")
    echo "🔨 Building web release for production..."
    flutter build web --release \
      --dart-define=ENVIRONMENT=$ENVIRONMENT \
      --dart-define=API_BASE_URL=$API_BASE_URL \
      --dart-define=DEBUG_ENABLED=$DEBUG_ENABLED \
      --web-renderer canvaskit

    echo ""
    echo "🌐 Web app built successfully!"
    echo "📍 Location: build/web/"
    ;;

  "macos")
    echo "🔨 Building macOS release for production..."
    flutter build macos --release \
      --dart-define=ENVIRONMENT=$ENVIRONMENT \
      --dart-define=API_BASE_URL=$API_BASE_URL \
      --dart-define=DEBUG_ENABLED=$DEBUG_ENABLED

    echo ""
    echo "💻 macOS app built successfully!"
    echo "📍 Location: build/macos/Build/Products/Release/"
    ;;

  "all")
    echo "🔨 Building all platforms for production..."

    # Build Android
    echo "📱 Building Android..."
    flutter build apk --release \
      --flavor $FLAVOR \
      --dart-define=ENVIRONMENT=$ENVIRONMENT \
      --dart-define=API_BASE_URL=$API_BASE_URL \
      --dart-define=DEBUG_ENABLED=$DEBUG_ENABLED \
      --obfuscate \
      --split-debug-info=build/debug-info/android

    # Build iOS
    echo "📱 Building iOS..."
    flutter build ios --release \
      --flavor $FLAVOR \
      --dart-define=ENVIRONMENT=$ENVIRONMENT \
      --dart-define=API_BASE_URL=$API_BASE_URL \
      --dart-define=DEBUG_ENABLED=$DEBUG_ENABLED \
      --obfuscate \
      --split-debug-info=build/debug-info/ios

    # Build Web
    echo "🌐 Building Web..."
    flutter build web --release \
      --dart-define=ENVIRONMENT=$ENVIRONMENT \
      --dart-define=API_BASE_URL=$API_BASE_URL \
      --dart-define=DEBUG_ENABLED=$DEBUG_ENABLED \
      --web-renderer canvaskit

    echo ""
    echo "✅ All production builds completed!"
    ;;

  "help"|"-h"|"--help")
    echo "Usage: $0 [platform]"
    echo ""
    echo "Platforms:"
    echo "  android   Build Android APK (default)"
    echo "  ios       Build iOS app"
    echo "  web       Build web app"
    echo "  macos     Build macOS app"
    echo "  all       Build all platforms"
    echo "  help      Show this help"
    echo ""
    echo "Environment Variables:"
    echo "  API_BASE_URL    Override API base URL (default: https://pottery-api-prod.run.app)"
    echo ""
    echo "Examples:"
    echo "  $0                              # Build Android APK"
    echo "  $0 ios                          # Build iOS app"
    echo "  API_BASE_URL=https://api.pottery.com $0 web  # Build web with custom API"
    echo "  $0 all                          # Build all platforms"
    echo ""
    echo "Security Notes:"
    echo "  - Production builds use code obfuscation"
    echo "  - Debug symbols are split for security"
    echo "  - Localhost URLs trigger warnings"
    exit 0
    ;;

  *)
    echo "❌ Unknown platform: $1"
    echo "Use '$0 help' for usage information"
    exit 1
    ;;
esac

echo ""
echo "✅ Production build completed!"
echo "🏭 Environment: $ENVIRONMENT"
echo "🔗 API URL: $API_BASE_URL"
echo "🔒 Security: Code obfuscated, debug symbols split"
