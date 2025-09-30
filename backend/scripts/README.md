# Firebase Setup Scripts

This directory contains scripts for setting up Firebase infrastructure for the Pottery App.

## setup-firebase-complete.sh

**Enhanced Firebase setup script with merge capability**

This script sets up Firebase for both development and production environments while preserving existing configurations.

### Features

- ✅ **Merge-friendly**: Doesn't overwrite existing configurations
- ✅ **Multi-environment**: Supports dev (pottery-app-456522) and prod (pottery-app-prod)
- ✅ **Environment-aware**: Works with the frontend's environment configuration system
- ✅ **Complete setup**: Creates Firebase projects, apps, storage, and Firestore
- ✅ **Smart resource reuse**: Detects and reuses existing Firebase apps and OAuth clients
- ✅ **Directory validation**: Ensures script runs from correct location
- ✅ **Configuration extraction**: Automatically extracts and merges Firebase config values

### What it does

1. **Backend Setup**:
   - Creates production GCP project (pottery-app-prod)
   - Enables required APIs for both dev and prod projects
   - Sets up Firestore databases and Cloud Storage buckets
   - Creates/reuses OAuth clients for authentication

2. **Frontend Configuration**:
   - Merges production Firebase config into `frontend/lib/src/config/firebase_options_env.dart`
   - Replaces PLACEHOLDER values with actual production configuration
   - Supports web and Android platforms (iOS removed - no Apple Developer account)
   - Preserves existing development configuration
   - Creates backup of original file before modification

3. **Backend Environment Files**:
   - Updates `.env.dev` and `.env.prod` with correct project IDs
   - Merges new values without overwriting existing configurations
   - Creates backups before making changes

4. **Firebase Apps**:
   - Creates/reuses web apps for both environments
   - Creates/reuses Android apps for both environments
   - Automatically detects existing apps to prevent duplicates

### Usage

**⚠️ Important**: Script must be run from the `backend/scripts/` directory

```bash
# Navigate to the correct directory
cd pottery-backend/backend/scripts

# Run the setup script
./setup-firebase-complete.sh
```

The script will validate the directory and show a clear error if run from the wrong location.

### Requirements

- Google Cloud SDK (`gcloud`)
- Firebase CLI (`firebase`)
- Authenticated with both gcloud and Firebase CLI
- Billing account available for production project creation

### File Changes

The script will:

1. **Merge into existing files**:
   - `frontend/lib/src/config/firebase_options_env.dart` - Replace PLACEHOLDER values
   - `.env.dev` and `.env.prod` - Update project-specific values

2. **Create backups**:
   - `firebase_options_env.dart.backup.{timestamp}`
   - `.env.dev.backup.{timestamp}` and `.env.prod.backup.{timestamp}`

3. **Generate temporary files** (cleaned up automatically):
   - `firebase_config_dev.json`
   - `firebase_config_prod.json`

### Environment System Integration

This script is designed to work with the frontend's environment configuration system:

- **Development builds**: Use `scripts/build_dev.sh` → points to pottery-app-456522
- **Production builds**: Use `scripts/build_prod.sh` → points to pottery-app-prod
- **Runtime environment detection**: Automatic based on `--dart-define=ENVIRONMENT=production`

## Deployment Workflow

After running the setup script, here's how to deploy and run your app in each environment:

### Backend Deployment

#### 1. Local Development (Docker on your Mac)
```bash
cd backend
./run_docker_local.sh              # Runs locally on http://localhost:8000
# Uses .env.dev config but runs on YOUR machine, not in cloud
# Access at: http://localhost:8000 or http://<your-ip>:8000
```

#### 2. Deploy to Development Cloud (Google Cloud Run)
```bash
cd backend
./build_and_deploy.sh              # Deploys to Google Cloud Run dev environment
# or explicitly:
./build_and_deploy.sh --env=dev    # Deploys to https://pottery-api-dev-1073709451179.us-central1.run.app
# This pushes code to Google Cloud and runs there, not locally
```

#### 3. Deploy to Production Cloud (Google Cloud Run)
```bash
cd backend
./build_and_deploy.sh --env=prod   # Deploys to https://pottery-api-prod.run.app
# Uses .env.prod config and runs on Google Cloud
```

### Frontend Deployment

The frontend now supports **three separate app installations** with different package IDs:

#### 1. Pottery Studio Local (connects to local Docker backend)
```bash
cd frontend
./scripts/build_dev.sh
# Select option 1: "Pottery Studio Local"
# Auto-detects your Mac's IP for Docker backend connection
# Creates app: com.pottery.app.local
```

#### 2. Pottery Studio Dev (connects to dev Cloud Run)
```bash
cd frontend
./scripts/build_dev.sh
# Select option 2: "Pottery Studio Dev"
# Connects to: https://pottery-api-dev.run.app
# Creates app: com.pottery.app.dev
```

#### 3. Pottery Studio Production (connects to production)
```bash
cd frontend
./scripts/build_prod.sh            # Fixed to production environment
# Connects to: https://pottery-api-prod.run.app
# Creates app: com.pottery.app
```

**Note**: All three apps can be installed simultaneously on the same device!

### Environment Matrix

| App Name | Package ID | Backend Firebase | Backend API | Build Command |
|----------|------------|------------------|-------------|---------------|
| **Pottery Studio Local** | com.pottery.app.local | pottery-app-456522 | http://your-ip:8000 | `build_dev.sh` → option 1 |
| **Pottery Studio Dev** | com.pottery.app.dev | pottery-app-456522 | pottery-api-dev-1073709451179.us-central1.run.app | `build_dev.sh` → option 2 |
| **Pottery Studio** | com.pottery.app | pottery-app-prod | pottery-api-prod.run.app | `build_prod.sh` |

### Testing Your Setup

1. **Test Local Stack**:
   ```bash
   # Terminal 1: Start local backend
   cd backend && ./run_docker_local.sh

   # Terminal 2: Build and install "Pottery Studio Local" app
   cd frontend && ./scripts/build_dev.sh
   # Select option 1 for local Docker backend
   ```

2. **Test Production Build**:
   ```bash
   cd frontend && ./scripts/build_prod.sh android
   ```

### Verification

After running the script:

1. **Check Firebase options**: Verify no PLACEHOLDER values remain
   ```bash
   grep "PLACEHOLDER_" ../frontend/lib/src/config/firebase_options_env.dart
   ```

2. **Test development build**:
   ```bash
   cd ../frontend
   ./scripts/build_dev.sh
   ```

3. **Test production build**:
   ```bash
   cd ../frontend
   ./scripts/build_prod.sh
   ```

### Troubleshooting

- **Permission errors**: Ensure authenticated with `gcloud auth login` and `firebase login`
- **Project already exists**: Script will skip creation and update existing project
- **Wrong directory error**: Run script from `pottery-backend/backend/scripts/` directory
- **Duplicate Firebase apps**: Script automatically detects and reuses existing apps
- **Placeholder values remain**: Check Firebase CLI authentication and project access

## Mobile App Debugging

### Flutter App Debugging on Android

#### Prerequisites
- Android device with USB debugging enabled
- Device connected via USB or wireless debugging

#### Real-time Logging

**Option 1: Flutter Logs (Flutter-specific only)**
```bash
# Navigate to frontend directory first
cd pottery-backend/frontend

# Basic Flutter logs
flutter logs

# Verbose Flutter logs
flutter logs --verbose

# Filtered Flutter logs
flutter logs | grep -E "(error|exception|auth|google)"
```

**Option 2: ADB Logs (All Android logs - Recommended)**
```bash
# All Android logs with filtering
adb logcat | grep -E "(pottery|google|auth|gms|GoogleAuth|GoogleSignIn)"

# Focused on authentication errors
adb logcat | grep -i "sign.*in\|auth\|google.*error\|gms.*error"

# App-specific logs
adb logcat | grep "com.pottery.app"
```

#### Google Sign-In Debugging

**Common Error: "Google sign-in failed: PlatformException(sign_in_failed, ...ApiException: 10)"**

Error code 10 = **SHA-1 fingerprint configuration mismatch**

**Fix Steps:**

1. **Get your debug SHA-1 fingerprint:**
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
   ```

2. **Add SHA-1 to Firebase Console:**
   - Go to: https://console.firebase.google.com/project/pottery-app-456522/settings/general
   - Find "PotteryStudio" Android app section
   - Click "Add fingerprint" button
   - Paste your SHA-1 fingerprint
   - Save changes

3. **Download updated google-services.json:**
   - After adding SHA-1, download the updated config file
   - Replace `frontend/android/app/google-services.json`

4. **Rebuild and test:**
   ```bash
   cd pottery-backend/frontend
   flutter clean
   ./scripts/build_dev.sh
   ```

**Debug Logging Setup:**
```bash
# Terminal 1: Start app
cd pottery-backend/frontend
./scripts/build_dev.sh

# Terminal 2: Monitor logs (from same directory)
cd pottery-backend/frontend
adb logcat | grep -E "(pottery|google|auth|GoogleAuth)"
```

#### Other Common Android Issues

**Build Errors:**
- **Gradle timeout**: First build can take 10-20 minutes
- **SDK missing**: Error suggests running Android Studio to install missing components
- **Package name mismatch**: Ensure `com.pottery.app` matches Firebase configuration

**Runtime Issues:**
- **Firebase config missing**: Check `google-services.json` exists and is valid
- **Network errors**: Ensure backend is running if testing local API
- **Permission errors**: Check Android app permissions in device settings

#### Debug Mode Features

When running `./scripts/build_dev.sh` (debug mode):
- **Hot reload**: Press 'r' in terminal to reload changes
- **Hot restart**: Press 'R' to restart app with new state
- **Debug logging**: All console.log and print statements visible
- **Development Firebase**: Uses pottery-app-456522 project
- **Local API**: Points to http://localhost:8000 by default

### Platform Support

- ✅ **Web**: Full support for both development and production
- ✅ **Android**: Full support with `com.pottery.app` package name
- ❌ **iOS**: Removed (requires Apple Developer account and bundle ID)

The script creates Firebase apps for supported platforms and extracts platform-specific configurations.

### Android Development Options

#### Option 1: Android Emulator (Recommended)

**Why use emulator for development:**
- Clean Google Play Services environment
- No device-specific authentication issues
- Easy to reset and test different scenarios
- Better debugging experience with cleaner logs

**Quick Setup on macOS:**
```bash
# Install Android Studio (if not already installed)
brew install --cask android-studio

# Create and start emulator via Android Studio:
# Tools → AVD Manager → Create Virtual Device → Pixel 7 → API 34 (Android 14)

# Or start from command line:
~/Library/Android/sdk/emulator/emulator @Pixel_7_API_34
```

**Development workflow with emulator:**
```bash
# Terminal 1: Start emulator
~/Library/Android/sdk/emulator/emulator @Pixel_7_API_34

# Terminal 2: Run Flutter app
cd pottery-backend/frontend
./scripts/build_dev.sh

# Terminal 3: Monitor clean emulator logs
adb -s emulator-5554 logcat | grep -E "(pottery|google|auth)"

# Terminal 4: Backend (if testing local API)
cd pottery-backend/backend
./run_docker_local.sh
```

#### Option 2: Physical Android Device

**Good for:**
- Testing real device performance
- Testing device-specific features
- Final testing before release

**Potential issues:**
- Device-specific Google Play Services authentication problems
- More complex debugging due to system-level interference
- May require Google account re-authentication for testing

**Setup**: See [Flutter Mobile Debugging Guide](../frontend/DEBUGGING.md) for complete physical device setup instructions.
