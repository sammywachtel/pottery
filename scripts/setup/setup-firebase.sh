#!/bin/bash

# Firebase Setup Script
# Configures Firebase for all environments including SHA-1 fingerprints

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔥 Firebase Setup Script"
echo "========================"

# Get current SHA-1
echo "📱 Getting your debug SHA-1 fingerprint..."
SHA1=$(keytool -list -v -keystore ~/.android/debug.keystore \
    -alias androiddebugkey -storepass android -keypass android 2>/dev/null | \
    grep "SHA1:" | awk '{print $2}')

if [ -z "$SHA1" ]; then
    echo "❌ Could not get SHA-1 fingerprint"
    echo "   Make sure Android debug keystore exists"
    exit 1
fi

echo "✅ Your SHA-1: $SHA1"
echo ""

# Check Firebase apps
echo "📋 Checking Firebase apps..."
firebase apps:list --project=pottery-app-456522

echo ""
echo "📱 iOS Apps and SHA-1 Configuration"
echo "=================================="
echo ""
echo "🤖 AUTOMATED: iOS apps for macOS support"
echo "   The setup-firebase-complete.sh script automatically creates iOS apps"
echo ""
echo "⚠️  MANUAL STEP: Add SHA-1 Fingerprints"
echo "1. Open: https://console.firebase.google.com/project/pottery-app-456522/settings/general"
echo "2. For EACH Android app (Pottery Studio Dev, Pottery Studio Local, PotteryStudio):"
echo "   a. Click on the app to expand it"
echo "   b. Click 'Add fingerprint'"
echo "   c. Paste: $SHA1"
echo "   d. Click 'Save'"
echo ""
echo "3. After adding all fingerprints:"
echo "   a. Click 'Download google-services.json'"
echo "   b. Save to: $PROJECT_ROOT/frontend/android/app/google-services.json"
echo ""
echo "Press Enter when you've completed the SHA-1 steps..."
read -r

# Verify the file was updated
if [ -f "$PROJECT_ROOT/frontend/android/app/google-services.json" ]; then
    echo "✅ google-services.json found"

    # Check if SHA-1 is in the file
    if grep -q "${SHA1,,}" "$PROJECT_ROOT/frontend/android/app/google-services.json"; then
        echo "✅ SHA-1 fingerprint confirmed in google-services.json"
    else
        echo "⚠️  SHA-1 not found in google-services.json"
        echo "   Make sure you downloaded the file after adding fingerprints"
    fi
else
    echo "❌ google-services.json not found"
    echo "   Please download and place in frontend/android/app/"
fi

# macOS configuration note
echo ""
echo "🍎 macOS Configuration:"
echo "   ✅ iOS apps and macOS configuration is handled by setup-firebase-complete.sh"
echo "   Run that script to automatically create iOS apps and configure macOS"

echo ""
echo "✅ Firebase setup complete!"
echo ""
echo "Test with:"
echo "  ./scripts/frontend/build-dev.sh     # Build dev app"
echo "  ./scripts/frontend/build-local.sh   # Build local app"
echo "  flutter run -d macos --dart-define=API_BASE_URL=http://localhost:8000  # Test macOS"
