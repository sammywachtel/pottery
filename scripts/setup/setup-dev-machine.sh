#!/bin/bash

# Developer Machine Setup Script
# Sets up a development machine with all required tools

set -e

echo "🛠️  Setting Up Developer Machine"
echo "================================"

# Check for required tools
echo "📋 Checking required tools..."

check_tool() {
    if command -v $1 &> /dev/null; then
        echo "✅ $1 is installed"
    else
        echo "❌ $1 is not installed"
        echo "   Please install $1 and run this script again"
        exit 1
    fi
}

check_tool flutter
check_tool gcloud
check_tool firebase
check_tool docker
check_tool keytool

# Setup gcloud
echo ""
echo "🔐 Setting up Google Cloud authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "Please authenticate with Google Cloud:"
    gcloud auth login
else
    echo "✅ Already authenticated as: $(gcloud auth list --filter=status:ACTIVE --format='value(account)')"
fi

# Setup Firebase
echo ""
echo "🔥 Setting up Firebase authentication..."
firebase login

# Setup Application Default Credentials
echo ""
echo "🔑 Setting up Application Default Credentials..."
if [ ! -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then
    gcloud auth application-default login
else
    echo "✅ Application Default Credentials already configured"
fi

# Get debug SHA-1 fingerprint
echo ""
echo "🔏 Your debug SHA-1 fingerprint:"
keytool -list -v -keystore ~/.android/debug.keystore \
    -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA1:" || echo "❌ Debug keystore not found"

echo ""
echo "📝 IMPORTANT: Add this SHA-1 to Firebase Console for all apps:"
echo "   1. Go to https://console.firebase.google.com/project/pottery-app-456522/settings/general"
echo "   2. Add SHA-1 to: Pottery Studio Dev, Pottery Studio Local, PotteryStudio"
echo "   3. Download google-services.json"
echo "   4. Place in frontend/android/app/"

echo ""
echo "✅ Developer machine setup complete!"
