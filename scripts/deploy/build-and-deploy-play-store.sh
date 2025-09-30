#!/bin/bash

# Opening move: Build and deploy Pottery Studio app to Google Play Store
# This script handles the complete deployment pipeline for managed Workspace distribution

set -e  # Exit on error

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
FLAVOR="${FLAVOR:-prod}"
BUILD_TYPE="${BUILD_TYPE:-aab}"  # aab or apk
TRACK="${TRACK:-internal}"  # internal, alpha, beta, production
SKIP_BUILD="${SKIP_BUILD:-false}"
SKIP_UPLOAD="${SKIP_UPLOAD:-false}"
DRY_RUN="${DRY_RUN:-false}"

# Show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Build and deploy Flutter app to Google Play Store

OPTIONS:
    --flavor FLAVOR         Build flavor: local, dev, prod (default: prod)
    --build-type TYPE       Build type: aab or apk (default: aab)
    --track TRACK           Release track: internal, alpha, beta, production (default: internal)
    --skip-build            Skip the build step (use existing artifact)
    --skip-upload           Only build, don't upload to Play Store
    --dry-run               Show what would be done without actually doing it
    -h, --help              Show this help message

EXAMPLES:
    # Build and deploy to internal testing
    $0

    # Build AAB for production track
    $0 --track production

    # Build APK only (no upload)
    $0 --build-type apk --skip-upload

    # Dry run to see what would happen
    $0 --dry-run

ENVIRONMENT VARIABLES:
    FLAVOR                  Same as --flavor flag
    BUILD_TYPE              Same as --build-type flag
    TRACK                   Same as --track flag
    SKIP_BUILD              Set to 'true' to skip build
    SKIP_UPLOAD             Set to 'true' to skip upload
    DRY_RUN                 Set to 'true' for dry run
    API_BASE_URL            API endpoint URL (auto-set based on flavor)

REQUIRED SETUP:
    1. Create keystore: ~/pottery-keystore/pottery-release-key.jks
    2. Create key.properties: ~/pottery-keystore/key.properties
    3. Service account key: ~/pottery-keystore/play-console-sa-key.json
    4. Google Play Developer account configured

See .local_docs/DEPLOYMENT_GUIDE.md for full setup instructions.
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --flavor)
            FLAVOR="$2"
            shift 2
            ;;
        --build-type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        --track)
            TRACK="$2"
            shift 2
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-upload)
            SKIP_UPLOAD=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main play: Validate environment and prerequisites
log_info "🚀 Starting Pottery Studio deployment pipeline"
log_info "Configuration:"
echo "  - Flavor: $FLAVOR"
echo "  - Build type: $BUILD_TYPE"
echo "  - Release track: $TRACK"
echo "  - Skip build: $SKIP_BUILD"
echo "  - Skip upload: $SKIP_UPLOAD"
echo "  - Dry run: $DRY_RUN"
echo ""

# Set API URL based on flavor
case $FLAVOR in
    local)
        API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"
        ;;
    dev)
        API_BASE_URL="${API_BASE_URL:-https://pottery-api-dev.run.app}"
        ;;
    prod)
        API_BASE_URL="${API_BASE_URL:-https://pottery-api-prod.run.app}"
        ;;
    *)
        log_error "Invalid flavor: $FLAVOR. Must be local, dev, or prod."
        exit 1
        ;;
esac

log_info "API Base URL: $API_BASE_URL"

# Validate Flutter installation
if ! command -v flutter &> /dev/null; then
    log_error "Flutter not found. Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

log_success "Flutter found: $(flutter --version | head -n 1)"

# Validate frontend directory
if [ ! -d "$FRONTEND_DIR" ]; then
    log_error "Frontend directory not found: $FRONTEND_DIR"
    exit 1
fi

cd "$FRONTEND_DIR"

# Check if keystore files exist (for release builds)
KEYSTORE_DIR="$HOME/pottery-keystore"
if [ "$FLAVOR" != "local" ]; then
    if [ ! -f "$KEYSTORE_DIR/pottery-release-key.jks" ]; then
        log_warning "Release keystore not found: $KEYSTORE_DIR/pottery-release-key.jks"
        log_warning "App will be signed with debug key (not suitable for Play Store upload)"
        log_info "See .local_docs/DEPLOYMENT_GUIDE.md Step 1 to create release keystore"
    else
        log_success "Release keystore found"
    fi

    if [ ! -f "$KEYSTORE_DIR/key.properties" ]; then
        log_warning "key.properties not found: $KEYSTORE_DIR/key.properties"
    else
        log_success "key.properties found"
    fi
fi

# Check for service account key (for uploads)
if [ "$SKIP_UPLOAD" = false ]; then
    if [ ! -f "$KEYSTORE_DIR/play-console-sa-key.json" ]; then
        log_error "Service account key not found: $KEYSTORE_DIR/play-console-sa-key.json"
        log_error "Cannot upload to Play Store without service account credentials"
        log_info "See .local_docs/DEPLOYMENT_GUIDE.md Step 3 to create service account"
        exit 1
    else
        log_success "Service account key found"
    fi
fi

# Big play: Build the app
if [ "$SKIP_BUILD" = false ]; then
    log_info "📦 Building app..."

    # Get version from pubspec.yaml
    VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
    BUILD_NAME=$(echo "$VERSION" | cut -d'+' -f1)
    BUILD_NUMBER=$(echo "$VERSION" | cut -d'+' -f2)

    log_info "Version: $BUILD_NAME+$BUILD_NUMBER"

    # Clean previous builds
    if [ "$DRY_RUN" = false ]; then
        log_info "Cleaning previous builds..."
        flutter clean
        flutter pub get
    else
        log_info "[DRY RUN] Would run: flutter clean && flutter pub get"
    fi

    # Build command
    if [ "$BUILD_TYPE" = "aab" ]; then
        BUILD_CMD="flutter build appbundle --release --flavor $FLAVOR --dart-define=API_BASE_URL=$API_BASE_URL --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER"
        BUILD_OUTPUT="build/app/outputs/bundle/${FLAVOR}Release/app-${FLAVOR}-release.aab"
    else
        BUILD_CMD="flutter build apk --release --flavor $FLAVOR --dart-define=API_BASE_URL=$API_BASE_URL --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER"
        BUILD_OUTPUT="build/app/outputs/apk/${FLAVOR}/release/app-${FLAVOR}-release.apk"
    fi

    log_info "Running: $BUILD_CMD"

    if [ "$DRY_RUN" = false ]; then
        if ! eval "$BUILD_CMD"; then
            log_error "Build failed!"
            exit 1
        fi

        # Verify build artifact exists
        if [ ! -f "$BUILD_OUTPUT" ]; then
            log_error "Build artifact not found: $BUILD_OUTPUT"
            exit 1
        fi

        BUILD_SIZE=$(du -h "$BUILD_OUTPUT" | cut -f1)
        log_success "Build completed: $BUILD_OUTPUT ($BUILD_SIZE)"
    else
        log_info "[DRY RUN] Would build and create: $BUILD_OUTPUT"
        # For dry run, simulate successful build
        BUILD_OUTPUT="build/app/outputs/bundle/${FLAVOR}Release/app-${FLAVOR}-release.aab"
    fi
else
    log_info "⏭️  Skipping build (using existing artifact)"

    # Determine expected artifact path
    if [ "$BUILD_TYPE" = "aab" ]; then
        BUILD_OUTPUT="build/app/outputs/bundle/${FLAVOR}Release/app-${FLAVOR}-release.aab"
    else
        BUILD_OUTPUT="build/app/outputs/apk/${FLAVOR}/release/app-${FLAVOR}-release.apk"
    fi

    # Verify existing artifact
    if [ "$DRY_RUN" = false ] && [ ! -f "$BUILD_OUTPUT" ]; then
        log_error "Expected build artifact not found: $BUILD_OUTPUT"
        log_error "Run without --skip-build to build the app first"
        exit 1
    fi
fi

# Victory lap: Upload to Play Store
if [ "$SKIP_UPLOAD" = false ]; then
    log_info "📤 Uploading to Google Play Store..."

    # Call Python upload script
    UPLOAD_SCRIPT="$SCRIPT_DIR/upload-to-play-store.py"

    if [ ! -f "$UPLOAD_SCRIPT" ]; then
        log_error "Upload script not found: $UPLOAD_SCRIPT"
        log_error "Please create the Python upload script (see DEPLOYMENT_GUIDE.md)"
        exit 1
    fi

    if [ "$DRY_RUN" = false ]; then
        log_info "Uploading $BUILD_TYPE to $TRACK track..."

        # Set environment variables for Python script
        export GOOGLE_APPLICATION_CREDENTIALS="$KEYSTORE_DIR/play-console-sa-key.json"
        export PACKAGE_NAME="com.pottery.app"
        export BUILD_FILE="$BUILD_OUTPUT"
        export PLAY_TRACK="$TRACK"

        if python3 "$UPLOAD_SCRIPT"; then
            log_success "✅ Upload successful!"
            log_info "App uploaded to $TRACK track"
            log_info "Visit Play Console to review and publish: https://play.google.com/console"
        else
            log_error "Upload failed. Check error messages above."
            exit 1
        fi
    else
        log_info "[DRY RUN] Would upload to Play Store:"
        echo "  - Package: com.pottery.app"
        echo "  - File: $BUILD_OUTPUT"
        echo "  - Track: $TRACK"
        echo "  - Service account: $KEYSTORE_DIR/play-console-sa-key.json"
    fi
else
    log_info "⏭️  Skipping upload"
    log_info "Build artifact ready at: $BUILD_OUTPUT"
    log_info "You can manually upload this to Play Console"
fi

# Final summary
echo ""
log_success "🎉 Deployment pipeline completed!"
echo ""
echo "Summary:"
echo "  - Flavor: $FLAVOR"
echo "  - Build: $BUILD_OUTPUT"
if [ "$SKIP_UPLOAD" = false ]; then
    echo "  - Uploaded to: $TRACK track"
    echo "  - Next: Review release in Play Console"
else
    echo "  - Upload: Skipped (manual upload required)"
fi
echo ""

# This looks odd, but it saves us from forgetting to update version numbers
if [ "$SKIP_UPLOAD" = false ] && [ "$DRY_RUN" = false ]; then
    log_info "💡 Don't forget to:"
    echo "  1. Increment build number in pubspec.yaml for next release"
    echo "  2. Review and publish release in Play Console"
    echo "  3. Monitor crash reports and user feedback"
    echo "  4. Update DEPLOYMENT_GUIDE.md with any issues encountered"
fi
