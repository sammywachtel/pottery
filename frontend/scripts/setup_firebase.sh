#!/bin/bash

# Firebase Configuration Setup Script
# This script guides you through setting up Firebase for the pottery app

echo "🔥 Firebase Authentication Setup for Pottery App"
echo "=================================================="
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install it first:"
    echo "   npm install -g firebase-tools"
    echo "   firebase login"
    exit 1
fi

# Check if FlutterFire CLI is installed
if ! command -v flutterfire &> /dev/null; then
    echo "❌ FlutterFire CLI not found. Installing..."
    dart pub global activate flutterfire_cli
    echo "✅ FlutterFire CLI installed"
fi

echo "📋 Before running this script, ensure you have:"
echo "   ✓ Created a Firebase project"
echo "   ✓ Enabled Authentication with Email/Password and Google Sign-In"
echo "   ✓ Run 'firebase login' to authenticate"
echo ""

read -p "Press Enter to continue, or Ctrl+C to exit..."

echo ""
echo "🚀 Running flutterfire configure..."
echo "   This will generate lib/firebase_options.dart with your project settings"
echo ""

# Run flutterfire configure
flutterfire configure

echo ""
echo "✅ Firebase configuration complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Verify lib/firebase_options.dart was created with your project settings"
echo "   2. Create an admin user in Firebase Console:"
echo "      - Go to Authentication > Users"
echo "      - Add a new user with email: admin@potteryapp.test"
echo "      - Set a secure password"
echo "   3. Update your backend to verify Firebase ID tokens"
echo "   4. Test authentication in the app"
echo ""
echo "📖 See FIREBASE_SETUP.md for detailed configuration instructions"
