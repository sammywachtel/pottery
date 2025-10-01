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
    echo "🔨 Building Android APK for production..."
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

  "appbundle"|"aab")
    echo "🔨 Building AAB for Play Store (production)..."

    # Opening move: read current version from pubspec.yaml
    PUBSPEC_PATH="$(dirname "$(dirname "${BASH_SOURCE[0]}")")/pubspec.yaml"
    CURRENT_VERSION=$(grep "^version:" "$PUBSPEC_PATH" | sed 's/version: //')
    BUILD_NAME=$(echo $CURRENT_VERSION | cut -d'+' -f1)
    BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)

    # Main play: increment build number and minor version (prod gets minor bumps)
    NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
    MAJOR=$(echo $BUILD_NAME | cut -d'.' -f1)
    MINOR=$(echo $BUILD_NAME | cut -d'.' -f2)
    PATCH=$(echo $BUILD_NAME | cut -d'.' -f3)
    NEW_MINOR=$((MINOR + 1))
    NEW_BUILD_NAME="$MAJOR.$NEW_MINOR.0"

    echo "📋 Version Information:"
    echo "   Current: $BUILD_NAME+$BUILD_NUMBER"
    echo "   New:     $NEW_BUILD_NAME+$NEW_BUILD_NUMBER"
    echo ""

    # Confirm production build
    echo "⚠️  This is a PRODUCTION build with version $NEW_BUILD_NAME+$NEW_BUILD_NUMBER"
    echo ""
    read -p "Continue with production AAB build? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "❌ Build cancelled"
      exit 1
    fi

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
      --build-number=$NEW_BUILD_NUMBER \
      --obfuscate \
      --split-debug-info=build/debug-info

    echo ""
    echo "📦 AAB Location: build/app/outputs/bundle/${FLAVOR}Release/app-${FLAVOR}-release.aab"
    echo "🎯 Ready for Play Store production upload!"
    echo "🔒 Security: Code obfuscated, debug symbols split"
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
    echo "  appbundle Build AAB for Play Store (auto-increments version)"
    echo "  aab       Alias for appbundle"
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
    echo "  $0 appbundle                    # Build AAB for Play Store"
    echo "  $0 aab                          # Build AAB (alias)"
    echo "  $0 ios                          # Build iOS app"
    echo "  API_BASE_URL=https://api.pottery.com $0 web  # Build web with custom API"
    echo "  $0 all                          # Build all platforms"
    echo ""
    echo "Versioning:"
    echo "  - Dev builds increment PATCH version (1.0.0 -> 1.0.1)"
    echo "  - Prod builds increment MINOR version (1.0.0 -> 1.1.0)"
    echo "  - Build number always increments (+1, +2, +3...)"
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
