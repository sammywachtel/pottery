# 🎯 Pottery App - Centralized Deployment Guide

This directory contains all scripts and configuration needed to deploy the Pottery App across all environments.

## 📂 Directory Structure

```
scripts/
├── backend/          # Backend deployment scripts
│   ├── deploy-local.sh    # Deploy to local Docker
│   ├── deploy-dev.sh      # Deploy to Cloud Run (dev)
│   ├── deploy-prod.sh     # Deploy to Cloud Run (prod)
│   └── fix-signed-urls.sh # Fix photo loading issues
│
├── frontend/         # Frontend build and run scripts
│   ├── build-local.sh     # Build Android APK → local backend
│   ├── build-dev.sh       # Build Android APK/AAB → dev backend
│   ├── build-prod.sh      # Build Android APK/AAB → prod backend
│   ├── run-web-local.sh   # Run web app → local Docker backend
│   └── run-web-dev.sh     # Run web app → Cloud Run dev backend
│
├── config/          # Environment configurations
│   ├── env.local.sh      # Local environment variables
│   ├── env.dev.sh        # Development environment variables
│   └── env.prod.sh       # Production environment variables
│
└── setup/           # Initial setup scripts
    ├── setup-firebase.sh       # Configure Firebase
    ├── setup-gcp-project.sh    # Setup GCP projects
    └── setup-dev-machine.sh    # Setup developer machine
```

## 🚀 Quick Start

### Prerequisites
- Flutter SDK installed
- Google Cloud SDK (`gcloud`) authenticated
- Firebase CLI (`firebase`) authenticated
- Docker installed (for local development)
- Android device/emulator with USB debugging

### 1️⃣ Initial Setup (Run Once)

```bash
# Setup your development machine
./scripts/setup/setup-dev-machine.sh

# Setup Google Cloud projects
./scripts/setup/setup-gcp-project.sh

# Configure Firebase (includes SHA-1 fingerprints)
./scripts/setup/setup-firebase.sh
```

## 💻 Development Workflow

### Local Development (Docker + Phone)

```bash
# 1. Start backend locally
./backend/run_docker_local.sh

# 2. Build and install mobile app
./frontend/scripts/build_dev.sh

# App: "Pottery Studio Local" → http://localhost:8000
```

### Development Environment (Cloud Run + Phone)

```bash
# 1. Deploy backend to Cloud Run
./scripts/backend/deploy-dev.sh

# 2. Build and install mobile app (APK for testing)
./frontend/scripts/build_dev.sh

# OR: Build AAB for Play Store internal testing
./frontend/scripts/build_dev.sh appbundle
# Output: Auto-increments version, builds AAB for Play Store

# App: "Pottery Studio Dev" → https://pottery-api-dev-1073709451179.us-central1.run.app
```

**AAB Build Features:**
- Auto-increments PATCH version (1.0.0 → 1.0.1)
- Auto-increments build number (+1, +2, +3...)
- Updates `pubspec.yaml` automatically
- Ready for Play Store internal testing track

### Production Environment

```bash
# 1. Deploy backend to Cloud Run (requires confirmation)
./scripts/backend/deploy-prod.sh

# 2. Build and install mobile app (APK for testing)
./frontend/scripts/build_prod.sh

# OR: Build AAB for Play Store production
./frontend/scripts/build_prod.sh appbundle
# Output: Auto-increments version, builds AAB for production

# App: "Pottery Studio" → https://pottery-api-prod.run.app
```

**Production AAB Build:**
- Auto-increments MINOR version (1.0.0 → 1.1.0)
- Auto-increments build number
- Includes code obfuscation and split debug symbols
- Requires confirmation prompt before building

### macOS Desktop Development

```bash
# 1. Start backend locally
./backend/run_docker_local.sh

# 2. Run macOS desktop app
cd frontend
flutter run -d macos --dart-define=API_BASE_URL=http://localhost:8000

# Alternative: Use dev backend
flutter run -d macos --dart-define=API_BASE_URL=https://pottery-api-dev-1073709451179.us-central1.run.app

# Build release version
flutter build macos --dart-define=API_BASE_URL=https://pottery-api-dev-1073709451179.us-central1.run.app
```

#### **Known macOS Issues:**
- ⚠️ **Google Sign-In configuration updated** (using Android client ID)
  - **Status**: App launches successfully, Firebase initializes
  - **Testing Required**: Click Google Sign-In button to verify authentication works
- ⚠️ **Font loading errors** (Google Fonts blocked by macOS network permissions)
- ⚠️ **Deployment target warnings** (requires Podfile update)
- ⚠️ **Limited Firebase Auth support** (use for UI testing only)
- ✅ **Basic functionality works** (navigation, API calls, UI rendering)

### Web Development

**Option 1: With Local Docker Backend**
```bash
# 1. Start backend locally
./backend/run_docker_local.sh

# 2. Run web app (connects to localhost:8000)
./frontend/scripts/build_dev.sh web
# Opens browser at: http://localhost:9102
```

**Option 2: With Cloud Run Dev Backend** (no local backend needed)
```bash
# Run web app (connects to Cloud Run dev)
./frontend/scripts/build_dev.sh web
# Opens browser at: http://localhost:9102
```

**Why Port 9102?**
- Port 9102 is pre-authorized in Firebase OAuth configuration
- Fixes Google Sign-In "404 popup_closed" error
- Ensures authentication works correctly on web

## 📱 App Configurations

### Mobile Apps (Android)

| App Name | Package | Backend | Use Case |
|----------|---------|---------|----------|
| **Pottery Studio Local** | com.pottery.app.local | http://localhost:8000 | Local testing |
| **Pottery Studio Dev** | com.pottery.app.dev | Cloud Run Dev | Integration testing |
| **Pottery Studio** | com.pottery.app | Cloud Run Prod | Production |

**Note:** All three apps can be installed simultaneously on the same device!

### Desktop/Web Apps

| Platform | Command | Backend | Use Case |
|----------|---------|---------|----------|
| **macOS Desktop** | `flutter run -d macos` | Configurable | Native macOS development |
| **Web Browser** | `flutter run -d web` | Configurable | Cross-platform testing |

## 🔑 Environment Variables

All environment variables are centralized in `scripts/config/`:

- **env.local.sh** - Local Docker configuration
- **env.dev.sh** - Development Cloud Run configuration
- **env.prod.sh** - Production Cloud Run configuration

### Key Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `GCP_PROJECT_ID` | Google Cloud project | pottery-app-456522 |
| `FIREBASE_PROJECT_ID` | Firebase project | pottery-app-456522 |
| `GCS_BUCKET_NAME` | Storage bucket | pottery-app-dev-456522-1759003953 |
| `GOOGLE_CLOUD_PROJECT` | Required for Firebase in Cloud Run | pottery-app-456522 |

## 🔧 Troubleshooting

### Google Sign-In Error (ApiException: 10)

**Problem:** SHA-1 fingerprint not configured in Firebase Console

**Solution:**
1. Get your debug SHA-1:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore \
     -alias androiddebugkey -storepass android -keypass android | grep SHA1
   ```

2. Add to Firebase Console:
   - Go to [Firebase Console](https://console.firebase.google.com/project/pottery-app-456522/settings/general)
   - Find your app (Dev/Local/Prod)
   - Click "Add fingerprint"
   - Paste SHA-1
   - Download new google-services.json
   - Replace in `frontend/android/app/`

### Photos Not Loading (Signed URL Error)

**Problem:** Cloud Run can't generate signed URLs

**Solution:**
```bash
./scripts/backend/fix-signed-urls.sh
```

This creates and mounts a service account key for signed URL generation.

### Backend Not Responding (501 Not Implemented)

**Problem:** Firebase not configured in Cloud Run

**Solution:** Ensure `GOOGLE_CLOUD_PROJECT` is set:
```bash
gcloud run services update pottery-api-dev \
  --region=us-central1 \
  --update-env-vars="GOOGLE_CLOUD_PROJECT=pottery-app-456522"
```

### App Shows Wrong Backend URL

**Problem:** Cached build configuration

**Solution:**
```bash
cd frontend
flutter clean
# Then rebuild with correct script
```

### macOS/Web Platform Issues

#### **macOS Deployment Target Warnings**
**Problem:** Xcode warnings about deprecated deployment targets
```
MACOSX_DEPLOYMENT_TARGET is set to 10.12, but range is 10.13 to 26.0.99
```

**Solution:** Update `macos/Podfile` to use newer deployment target:
```ruby
platform :osx, '10.13'
```

#### **Google Fonts Network Errors**
**Problem:** macOS blocks network requests to fonts.gstatic.com
```
SocketException: Connection failed (OS Error: Operation not permitted)
```

**Solutions:**
1. **Allow network access** in macOS app settings
2. **Use system fonts** instead of Google Fonts for macOS
3. **Bundle fonts locally** in the Flutter app

### macOS Google Sign-In Error 400 (Custom Scheme URIs)

**Problem:** "Custom scheme URIs are not allowed for 'WEB' client type"

**Root Cause:** macOS Flutter apps need iOS client configuration, not web client

**Solution:**
1. **Add iOS App to Firebase Console**:
   ```
   Go to: https://console.firebase.google.com/project/pottery-app-456522/settings/general
   Click: "Add app" → "iOS"
   iOS bundle ID: com.pottery.app (or your preferred bundle ID)
   App nickname: "Pottery Studio macOS"
   ```

2. **Download GoogleService-Info.plist**:
   - Download the iOS configuration file
   - Place in `frontend/ios/Runner/GoogleService-Info.plist`
   - Note: macOS can use iOS configuration

3. **Update macOS Info.plist with iOS Client ID**:
   ```
   Extract client_id from GoogleService-Info.plist
   Update GIDClientID in frontend/macos/Runner/Info.plist
   Update CFBundleURLSchemes with reversed client ID
   ```

4. **Alternative: Use Android Client ID** (✅ Currently Applied):
   - ✅ **Current Fix**: Using Android client ID from google-services.json
   - ✅ **Client ID**: `1073709451179-eg98ubeha74vcva7rnfpts1sjir3fol5.apps.googleusercontent.com`
   - ✅ **Status**: App launches successfully, no more crashes

**Testing Google Sign-In on macOS:**
```bash
# 1. Start backend locally
./backend/run_docker_local.sh

# 2. Run macOS app
cd frontend
flutter run -d macos --dart-define=API_BASE_URL=http://localhost:8000

# 3. In the app UI:
#    - Click "Sign in with Google" button
#    - Check if authentication popup works without "Custom scheme URIs" error
#    - Verify successful authentication flow
```

#### **General Desktop Limitations**
**Google Sign-In Issues:**
- Firebase Auth may have limited desktop support
- macOS requires iOS client configuration
- Mobile apps recommended for full authentication testing

**Photo Upload on Desktop:**
- Camera access may be limited
- Use file picker instead of camera
- Test photo features primarily on mobile

## 📊 Backend Status Checks

### Local Backend
```bash
curl http://localhost:8000/
docker logs pottery-backend
```

### Development Backend
```bash
curl https://pottery-api-dev-1073709451179.us-central1.run.app/
gcloud run services logs read pottery-api-dev --region=us-central1
```

### Production Backend
```bash
curl https://pottery-api-prod.run.app/
gcloud run services logs read pottery-api-prod --region=us-central1
```

## 🚨 Important Notes

1. **SHA-1 Fingerprint**: Required for ALL Firebase Android apps (dev, local, prod)
2. **Service Account Key**: Required for signed URLs in Cloud Run
3. **GOOGLE_CLOUD_PROJECT**: Must be set for Firebase to work in Cloud Run
4. **Multiple Apps**: Use Android build flavors to install all three apps simultaneously
5. **Environment Isolation**: Each environment uses separate Firebase projects in production

## 📖 Additional Documentation

- [Backend README](../backend/README.md) - Backend architecture details
- [Frontend README](../frontend/README.md) - Flutter app details
- [Firebase Setup](setup/FIREBASE_SETUP.md) - Detailed Firebase configuration
- [GCP Setup](setup/GCP_SETUP.md) - Google Cloud project setup

## 🛟 Support

- Check logs: `gcloud run services logs read <service-name> --region=us-central1`
- Firebase Console: https://console.firebase.google.com/project/pottery-app-456522
- Cloud Console: https://console.cloud.google.com/run?project=pottery-app-456522
