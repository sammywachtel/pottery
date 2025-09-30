# Firebase Multi-Environment Setup

## Overview

This guide explains how to set up separate Firebase projects for development and production environments, ensuring proper isolation and testing workflows.

## Architecture

### Environment Structure

```
Development Environment (pottery-app-456522)
├── Package: com.pottery.app.dev
├── Firebase Auth: Development users
├── Firestore: Development data
├── Cloud Storage: Development photos
└── Purpose: Internal testing, QA, development builds

Production Environment (pottery-app-prod)
├── Package: com.pottery.app
├── Firebase Auth: Real users
├── Firestore: Production data
├── Cloud Storage: Production photos
└── Purpose: End users, Play Store distribution
```

## Step 1: Create Production Firebase Project

### Via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project** or **Create a project**
3. Enter project name: `pottery-app-prod`
4. Continue through setup:
   - Enable Google Analytics (optional but recommended)
   - Choose analytics account or create new one
5. Click **Create project**

### Via gcloud CLI

```bash
# Create new GCP project for production
gcloud projects create pottery-app-prod \
  --name="Pottery App Production" \
  --set-as-default

# Enable Firebase for the project
gcloud services enable firebase.googleapis.com --project=pottery-app-prod
gcloud services enable firestore.googleapis.com --project=pottery-app-prod
gcloud services enable storage.googleapis.com --project=pottery-app-prod

# Link to Firebase (requires Firebase Console interaction)
echo "Visit https://console.firebase.google.com/ to complete Firebase setup"
```

## Step 2: Add Android Apps to Each Firebase Project

### Development Project (pottery-app-456522)

**Already configured with:**
- `com.pottery.app.dev` ✅
- `com.pottery.app.local` ✅

### Production Project (pottery-app-prod)

**Add the production app:**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: `pottery-app-prod`
3. Click gear icon → **Project settings**
4. Scroll to **Your apps** → Click **Add app** → **Android**
5. Register app:
   - **Package name**: `com.pottery.app`
   - **App nickname**: Pottery Studio
   - **Debug signing certificate SHA-1**: (optional for now, add later for Google Sign-In)
6. Download `google-services.json`
7. Click **Next** → **Continue to console**

## Step 3: Configure google-services.json Files

You need **different** `google-services.json` files for each flavor.

### Create Flavor-Specific Directories

```bash
cd frontend/android/app

# Create flavor-specific directories
mkdir -p src/dev
mkdir -p src/prod
mkdir -p src/local

# Move existing google-services.json to dev
cp google-services.json src/dev/google-services.json

# For local, use same as dev (points to pottery-app-456522)
cp google-services.json src/local/google-services.json

echo "✅ Flavor directories created"
```

### Download Production google-services.json

1. In Firebase Console for `pottery-app-prod`
2. Go to **Project settings** → **Your apps**
3. Find your Android app (`com.pottery.app`)
4. Click **google-services.json** download button
5. Save as: `frontend/android/app/src/prod/google-services.json`

### Verify Structure

```bash
cd frontend/android/app
tree src/*/google-services.json
```

Expected output:
```
src/dev/google-services.json     # Points to pottery-app-456522
src/local/google-services.json   # Points to pottery-app-456522
src/prod/google-services.json    # Points to pottery-app-prod
```

## Step 4: Update Build Configuration

The Android build system automatically picks up flavor-specific `google-services.json` files from `src/{flavor}/` directories. No build.gradle changes needed!

**How it works:**
- Building with `--flavor dev` → Uses `src/dev/google-services.json`
- Building with `--flavor prod` → Uses `src/prod/google-services.json`
- Building with `--flavor local` → Uses `src/local/google-services.json`

## Step 5: Set Up Backend Environments

### Backend API Endpoints

Update your backend to use separate GCP projects:

**Development Backend:**
```bash
# Deploy to pottery-app-456522
gcloud config set project pottery-app-456522
gcloud run deploy pottery-api-dev \
  --source=backend \
  --region=us-central1 \
  --allow-unauthenticated
```

**Production Backend:**
```bash
# Deploy to pottery-app-prod
gcloud config set project pottery-app-prod
gcloud run deploy pottery-api-prod \
  --source=backend \
  --region=us-central1 \
  --allow-unauthenticated
```

### Firestore & Cloud Storage

Each Firebase project automatically has separate Firestore and Cloud Storage:

**Development (pottery-app-456522):**
- Firestore: `(default)` database in pottery-app-456522
- Storage: `pottery-app-456522.firebasestorage.app`

**Production (pottery-app-prod):**
- Firestore: `(default)` database in pottery-app-prod
- Storage: `pottery-app-prod.firebasestorage.app`

## Step 6: Build Commands for Each Environment

### Development Build (Internal Testing)

```bash
cd frontend

# Build AAB for internal testing (uses pottery-app-456522)
flutter build appbundle \
  --release \
  --flavor dev \
  --dart-define=API_BASE_URL=https://pottery-api-dev-1073709451179.us-central1.run.app \
  --build-name=1.0.0 \
  --build-number=1

# Output: build/app/outputs/bundle/devRelease/app-dev-release.aab
# Package: com.pottery.app.dev
```

### Production Build (End Users)

```bash
cd frontend

# Build AAB for production (uses pottery-app-prod)
flutter build appbundle \
  --release \
  --flavor prod \
  --dart-define=API_BASE_URL=https://pottery-api-prod.run.app \
  --build-name=1.0.0 \
  --build-number=1

# Output: build/app/outputs/bundle/prodRelease/app-prod-release.aab
# Package: com.pottery.app
```

### Local Development Build

```bash
cd frontend

# Build for local testing (uses pottery-app-456522, local API)
flutter build apk \
  --release \
  --flavor local \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000 \
  --build-name=1.0.0 \
  --build-number=1

# Or run directly on device
flutter run \
  --flavor local \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Step 7: Deployment Workflows

### Development Workflow (Internal Testing)

```bash
# 1. Build dev flavor
./scripts/deploy/build-and-deploy-play-store.sh \
  --flavor dev \
  --track internal

# This deploys com.pottery.app.dev to internal testing track
# Team members can test without affecting production
```

### Production Workflow (End Users)

```bash
# 1. Test thoroughly in dev environment first

# 2. Build and deploy prod flavor
./scripts/deploy/build-and-deploy-play-store.sh \
  --flavor prod \
  --track internal  # Start with internal testing

# 3. After validation, promote to production
# (Done via Play Console or script)
```

## Step 8: Google Play Console Configuration

### Development App (com.pottery.app.dev)

1. Create app in Play Console: **Pottery Studio Dev**
2. Package name: `com.pottery.app.dev`
3. Upload to internal testing track
4. Assign to your team for testing
5. This app is ONLY for your organization (not public)

### Production App (com.pottery.app)

1. Create app in Play Console: **Pottery Studio**
2. Package name: `com.pottery.app`
3. Upload to internal testing first
4. After validation, promote to production track
5. Distribute via managed Google Play to your Workspace users

## Environment Variables Summary

### Development (dev flavor)
```bash
FLAVOR=dev
API_BASE_URL=https://pottery-api-dev-1073709451179.us-central1.run.app
FIREBASE_PROJECT=pottery-app-456522
PACKAGE_NAME=com.pottery.app.dev
```

### Production (prod flavor)
```bash
FLAVOR=prod
API_BASE_URL=https://pottery-api-prod.run.app
FIREBASE_PROJECT=pottery-app-prod
PACKAGE_NAME=com.pottery.app
```

## Testing Strategy

### Phase 1: Development Testing
- Deploy dev flavor (`com.pottery.app.dev`) to internal track
- Test with pottery-app-456522 Firebase project
- Iterate quickly without affecting production

### Phase 2: Production Validation
- Deploy prod flavor (`com.pottery.app`) to internal track first
- Validate with pottery-app-prod Firebase project
- Small group of testers validate production environment

### Phase 3: Production Rollout
- Promote to production track
- Distribute to all Workspace users
- Monitor closely

## Troubleshooting

### Wrong Firebase Project Being Used

**Symptom:** App connects to wrong Firestore database

**Solution:** Check which `google-services.json` is being used:
```bash
# Verify the correct file exists
cat frontend/android/app/src/prod/google-services.json | grep project_id
# Should show: "project_id": "pottery-app-prod"

cat frontend/android/app/src/dev/google-services.json | grep project_id
# Should show: "project_id": "pottery-app-456522"
```

### Build Fails with "No matching client found"

**Symptom:** Error during build: `No matching client found for package name`

**Solution:** Ensure the package name in the app is registered in the corresponding Firebase project:
- `com.pottery.app.dev` must be in `pottery-app-456522`
- `com.pottery.app` must be in `pottery-app-prod`

### Both Apps on Same Device

You can install BOTH apps on the same device because they have different package names:
- "Pottery Studio Dev" (`com.pottery.app.dev`) - Has dev icon/name
- "Pottery Studio" (`com.pottery.app`) - Has prod icon/name

They maintain completely separate data and cannot interfere with each other.

## Security Considerations

### Separate Data & Users
- Dev and prod environments have completely separate databases
- Test users in dev cannot access production data
- Production users never see development/test data

### Firebase Security Rules
Apply the same security rules to both projects:

```bash
# Deploy Firestore rules to dev
firebase deploy --only firestore:rules --project pottery-app-456522

# Deploy Firestore rules to prod
firebase deploy --only firestore:rules --project pottery-app-prod
```

### API Keys
Each Firebase project has its own API keys in `google-services.json`. These keys are safe to include in the app as they are paired with:
- Package name restrictions
- Firebase Security Rules
- Google Cloud project restrictions

## Quick Reference

| Environment | Firebase Project | Package Name | API URL | Play Store Track |
|------------|-----------------|--------------|---------|------------------|
| Local | pottery-app-456522 | com.pottery.app.local | localhost:8000 | N/A (local only) |
| Development | pottery-app-456522 | com.pottery.app.dev | pottery-api-dev.run.app | Internal testing |
| Production | pottery-app-prod | com.pottery.app | pottery-api-prod.run.app | Production |

## Next Steps

1. ✅ Create pottery-app-prod Firebase project
2. ✅ Add com.pottery.app to pottery-app-prod
3. ✅ Download prod google-services.json
4. ✅ Place in src/prod/ directory
5. ✅ Build prod flavor
6. ✅ Upload to Play Console
7. ✅ Test and validate
8. ✅ Promote to production

This setup ensures you can safely test changes in development without risking production data or user experience!
