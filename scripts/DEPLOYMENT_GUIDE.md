# Pottery App - Google Play Store Deployment Guide

## Overview

This guide covers deploying the Pottery Studio app to Google Play Store for internal testing and distribution to your Google Workspace organization via managed Google Play.

**Key Points:**
- Uses **existing build scripts** in `scripts/frontend/`
- Supports **dev and prod environments** with separate Firebase projects
- Deploys to **Play Store internal testing** first
- Distributes via **managed Google Play** for Workspace users

## Quick Reference: Existing Scripts

Your project already has build automation:

| Script | Purpose | Package | Backend |
|--------|---------|---------|---------|
| `scripts/frontend/build-local.sh` | Local development | com.pottery.app.local | localhost:8000 |
| `scripts/frontend/build-dev.sh` | Dev/testing | com.pottery.app.dev | pottery-api-dev |
| `scripts/frontend/build-prod.sh` | Production | com.pottery.app | pottery-api-prod |

**For Play Store deployment:**
- **Internal testing**: Use `build-dev.sh` → creates `com.pottery.app.dev`
- **Production release**: Use `build-prod.sh` → creates `com.pottery.app`

## Prerequisites

- [x] Google Play Developer account ($25 one-time fee)
- [x] Google Workspace admin access
- [x] `flutter`, `python3`, `gcloud`, `firebase` CLIs installed
- [x] Existing Firebase project: `pottery-app-456522` (dev)
- [ ] Create Firebase project: `pottery-app-prod` (production - optional for now)

## Part 1: Initial Setup (One-Time)

### Step 1: Create Release Keystore

```bash
# Create secure directory for credentials
mkdir -p ~/pottery-keystore
cd ~/pottery-keystore

# ==========================================
# PASSWORD SETUP
# ==========================================
# Create ONE strong password (16+ characters)
# Example: "MyP0ttery$ecure#3y2024!" (create your own!)
#
# Requirements:
#   - Mix of uppercase, lowercase, numbers, special characters
#   - Store in password manager (1Password, LastPass, etc.)
#   - ⚠️ IF YOU LOSE THIS PASSWORD, YOU CANNOT UPDATE YOUR APP!
# ==========================================

# Generate release keystore (replace YOUR_PASSWORD with your actual password)
keytool -genkey -v -keystore pottery-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias pottery-app \
  -dname "CN=Your Name, OU=Pottery, O=Your Org, L=City, ST=State, C=US" \
  -storepass YOUR_PASSWORD \
  -keypass YOUR_PASSWORD

# Create key.properties (use the SAME password)
cat > key.properties << EOF
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=pottery-app
storeFile=$HOME/pottery-keystore/pottery-release-key.jks
EOF

# Secure the files
chmod 600 pottery-release-key.jks key.properties

echo "✅ Keystore created successfully!"
echo "⚠️  Back up these files securely!"
```

**Important:** Your `frontend/android/app/build.gradle.kts` is already configured to use this keystore.

### Step 2: Enable Google Play Developer API

```bash
# Authenticate as your user account
gcloud auth login

# List projects and set active one
gcloud projects list
gcloud config set project pottery-app-456522  # Use your actual project ID

# Verify you're using your user account (not service account)
gcloud config list account

# Enable the API
gcloud services enable androidpublisher.googleapis.com

# Create service account for deployment automation
gcloud iam service-accounts create play-console-deployer \
  --display-name="Play Console Deployment"

# Download service account key
gcloud iam service-accounts keys create ~/pottery-keystore/play-console-sa-key.json \
  --iam-account=play-console-deployer@pottery-app-456522.iam.gserviceaccount.com

echo "✅ Service account created!"
```

**Security Note:**
- Store service account key securely
- Never commit to version control
- Rotate keys every 90 days

**Troubleshooting:**
- If you get "PERMISSION_DENIED", make sure you ran `gcloud auth login` first
- Verify you're an Owner or Editor of the GCP project

### Step 3: Create App in Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Click **Create app**
3. Fill in details:
   - **App name**: Pottery Studio Dev (or Pottery Studio for prod)
   - **Default language**: English (United States)
   - **App or game**: App
   - **Free or paid**: Free
4. Click **Create app**

**Note:** You can create the app structure without filling in all store listing details yet.

### Step 4: Invite Service Account to Play Console

**Updated Process (2025):**

1. Go to [Google Play Console](https://play.google.com/console)
2. Navigate to **Users and permissions** (left sidebar)
3. Click **Invite new users**
4. Enter service account email: `play-console-deployer@pottery-app-456522.iam.gserviceaccount.com`
5. Assign permissions:
   - ✅ **View app information and download bulk reports**
   - ✅ **Manage production releases**
   - ✅ **Manage testing track releases**
6. Click **Send invitation**

**Important:**
- Service account shows as "Pending" initially (this is normal)
- API access may take up to 24 hours to activate
- No manual acceptance needed

### Step 5: Install Python Dependencies

```bash
# Install Google API client for upload automation
pip3 install --upgrade google-auth google-api-python-client

echo "✅ Python dependencies installed!"
```

## Part 2: Building for Play Store

### Option A: Development Build (Recommended for Initial Testing)

Use your existing dev build script to create an AAB for internal testing:

```bash
# Build dev flavor AAB
cd /Users/samwachtel/PycharmProjects/potteryapp/pottery-backend

# Set environment variables for AAB build
export FLAVOR=dev
export API_BASE_URL=https://pottery-api-dev-1073709451179.us-central1.run.app

# Run the build (modify script to create AAB instead of APK)
./scripts/frontend/build-dev.sh
```

**Note:** Your current `build-dev.sh` script builds APK by default. To build AAB for Play Store, you need to modify the script or manually run:

```bash
cd frontend
flutter clean
flutter build appbundle \
  --release \
  --flavor dev \
  --dart-define=API_BASE_URL=https://pottery-api-dev-1073709451179.us-central1.run.app \
  --build-name=1.0.0 \
  --build-number=1

# Output: build/app/outputs/bundle/devRelease/app-dev-release.aab
```

### Option B: Production Build (After Setting Up pottery-app-prod)

Once you've created the `pottery-app-prod` Firebase project and configured it (see `FIREBASE_MULTI_ENV_SETUP.md`):

```bash
cd frontend
flutter clean
flutter build appbundle \
  --release \
  --flavor prod \
  --dart-define=API_BASE_URL=https://pottery-api-prod.run.app \
  --build-name=1.0.0 \
  --build-number=1

# Output: build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

### Build Output Locations

| Flavor | AAB Location | Package Name |
|--------|-------------|--------------|
| dev | `frontend/build/app/outputs/bundle/devRelease/app-dev-release.aab` | com.pottery.app.dev |
| prod | `frontend/build/app/outputs/bundle/prodRelease/app-prod-release.aab` | com.pottery.app |

## Part 3: Upload to Play Store

### Manual Upload (First Time)

1. In Play Console, go to **Testing > Internal testing**
2. Click **Create new release**
3. Upload the AAB (e.g., `app-dev-release.aab`)
4. Fill in release notes:
   ```
   Initial internal release for testing
   - Pottery item tracking and organization
   - Photo upload and management
   - Firebase authentication
   - Item measurements and notes
   ```
5. Click **Review release** → **Start rollout to Internal testing**

### Automated Upload (Subsequent Releases)

Use the deployment automation script:

```bash
# Set environment variables
export GOOGLE_APPLICATION_CREDENTIALS=~/pottery-keystore/play-console-sa-key.json
export PACKAGE_NAME=com.pottery.app.dev  # or com.pottery.app for prod
export BUILD_FILE=frontend/build/app/outputs/bundle/devRelease/app-dev-release.aab
export PLAY_TRACK=internal

# Run upload script
python3 scripts/deploy/upload-to-play-store.py
```

Or use the comprehensive deployment script:

```bash
./scripts/deploy/build-and-deploy-play-store.sh \
  --flavor dev \
  --track internal
```

**Note:** Service account API access must be active (can take up to 24 hours after invitation).

## Part 4: Configure Managed Google Play

### Enable Managed Google Play in Workspace

**Note:** The Managed Google Play setup process varies depending on your Google Workspace configuration.

#### Option A: Through Web and Mobile Apps
1. Go to [Google Workspace Admin Console](https://admin.google.com)
2. Navigate to **Apps > Web and mobile apps**
3. Look for **Add app > Add from Google Play Store**
4. This will enable Managed Google Play if not already enabled

#### Option B: Through Device Management
1. Go to **Devices > Mobile & endpoints > Settings > Universal**
2. Look for Android settings or Enterprise enrollment
3. Follow prompts to enable Android enterprise management
4. This automatically enables Managed Google Play

#### Option C: Direct Managed Google Play Setup
1. Visit [Google Play Enterprise](https://play.google.com/work)
2. Sign in with your Google Workspace admin account
3. Follow the setup wizard to bind your organization
4. Return to Admin Console after setup

### Make App Private to Organization

1. In [Play Console](https://play.google.com/console) → Your app
2. Go to **Release > Setup > Managed Google Play**
3. Click **Add to Managed Google Play**
4. Select **Private app** (restricted to your organization)
5. Enter your Google Workspace organization ID

### Assign to Users

Once Managed Google Play is enabled (see options above), assign your app to users:

#### Through Web and Mobile Apps (Most Common)
1. In [Admin Console](https://admin.google.com), go to **Apps > Web and mobile apps**
2. Click **Add app > Add from Google Play Store**
3. Search for "Pottery Studio Dev" (or your app name)
4. Click on your app and click **Select**
5. Configure installation settings:
   - **Installation policy**: Choose "Allow users to install" or "Force install"
   - **Users**: Select organizational units or groups
6. Click **Save**

#### Alternative: Through Managed Google Play Web Interface
1. Visit the Managed Google Play iframe URL (if configured)
2. Search for your private app
3. Approve and configure distribution

### Users Install the App

Selected users will see your app in Google Play Store under **"Work apps"** section and can install it directly.

## Part 5: Version Management

### Semantic Versioning

Follow this pattern in `frontend/pubspec.yaml`:

```yaml
version: MAJOR.MINOR.PATCH+BUILD_NUMBER
```

Examples:
- `1.0.0+1` - Initial release
- `1.0.1+2` - Bug fix
- `1.1.0+3` - New feature
- `2.0.0+4` - Breaking change

Increment:
- **BUILD_NUMBER**: Every Play Store upload
- **PATCH**: Bug fixes
- **MINOR**: New features (backwards compatible)
- **MAJOR**: Breaking changes

### Update Workflow

```bash
# 1. Update version in frontend/pubspec.yaml
# Change: version: 1.0.0+1
# To:     version: 1.0.1+2

# 2. Build new version
cd frontend
flutter build appbundle --release --flavor dev --build-name=1.0.1 --build-number=2

# 3. Upload to Play Store (manual or automated)

# 4. Test in internal track

# 5. Promote to production when ready
```

## Troubleshooting

### Build Errors

**"No matching client found for package name"**
- Firebase `google-services.json` doesn't have your package configured
- Solution: Add the app to Firebase Console and download new `google-services.json`
- Place in `frontend/android/app/src/{flavor}/google-services.json`

**"Unresolved reference: util"**
- Missing imports in `build.gradle.kts`
- Solution: Already fixed - imports are at top of file

### Upload Errors

**"Service account permission denied"**
- Service account not properly invited or API access not active
- Wait up to 24 hours after inviting service account
- Verify permissions in Play Console > Users and permissions

**"Package name mismatch"**
- App being uploaded doesn't match app in Play Console
- Verify package name: `com.pottery.app.dev` vs `com.pottery.app`

### Distribution Issues

**Users can't find app**
- Verify app is assigned to their organizational unit in Workspace Admin
- Check app is published to internal/production track
- Users should look in "Work apps" section of Play Store

### Firebase Authentication Issues

**"ApiException: 10" when signing in via Play Store**
- This is a SHA certificate fingerprint mismatch
- **Cause**: Google Play re-signs your app with their own signing key after upload
- **Solution**: Add Play Store's app signing certificate to Firebase

**Fix Steps:**
1. Get Play Store signing certificate:
   - Go to [Play Console](https://play.google.com/console) > Your app
   - Navigate to **Release > Setup > App signing**
   - Under "App signing key certificate", copy the SHA-1 fingerprint

2. Add to Firebase:
   - Go to [Firebase Console](https://console.firebase.google.com/) > Your project
   - **Project settings** > Scroll to "Your apps"
   - Find your Android app (e.g., `com.pottery.app.dev`)
   - Click **Add fingerprint**
   - Paste the Play Store SHA-1 fingerprint
   - Click **Save**

3. Download and deploy new config:
   ```bash
   # Download new google-services.json from Firebase Console
   # Place in: frontend/android/app/src/{flavor}/google-services.json

   # Rebuild AAB
   cd frontend
   flutter build appbundle --release --flavor dev

   # Upload new version to Play Store
   ```

**Important**: You need TWO SHA-1 fingerprints in Firebase:
- Your upload key SHA-1 (for local development/testing)
- Play Store's app signing key SHA-1 (for production distribution via Play Store)

## Environment Structure Summary

| Environment | Firebase Project | Package | Backend | Use Case |
|------------|-----------------|---------|---------|----------|
| **Local** | pottery-app-456522 | com.pottery.app.local | localhost:8000 | Local dev |
| **Dev/Testing** | pottery-app-456522 | com.pottery.app.dev | pottery-api-dev | Internal testing |
| **Production** | pottery-app-prod* | com.pottery.app | pottery-api-prod | End users |

*pottery-app-prod needs to be created - see `FIREBASE_MULTI_ENV_SETUP.md`

## Deployment Workflows

### Development Workflow (Current)

```bash
# 1. Make changes locally
./scripts/frontend/build-local.sh

# 2. Test with local backend
# App installs as "Pottery Studio Local"

# 3. When ready for team testing, build dev
flutter build appbundle --release --flavor dev

# 4. Upload to Play Store internal track
# Team members test "Pottery Studio Dev" app

# 5. Iterate based on feedback
```

### Production Workflow (Future)

```bash
# 1. Validate thoroughly in dev environment

# 2. Build production AAB
flutter build appbundle --release --flavor prod

# 3. Upload to internal track first
# Small group validates production environment

# 4. Promote to production track
# Distribute to all Workspace users via managed Google Play
```

## Related Documentation

- [Main Scripts README](README.md) - Overview of all deployment scripts
- [Firebase Multi-Environment Setup](FIREBASE_MULTI_ENV_SETUP.md) - Detailed Firebase configuration
- [Backend Deployment](backend/README.md) - Backend deployment guides
- [Frontend Build Scripts](frontend/) - Flutter build script details

## Support Resources

- [Google Play Console](https://play.google.com/console)
- [Workspace Admin Console](https://admin.google.com)
- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)

---

**Next Steps:**
1. ✅ Create keystore (Step 1)
2. ✅ Enable Play Developer API (Step 2)
3. ✅ Create app in Play Console (Step 3)
4. ✅ Invite service account (Step 4)
5. ✅ Build AAB (Part 2)
6. ⏳ Upload to Play Store (Part 3)
7. ⏳ Configure managed Google Play (Part 4)
8. ⏳ Test installation on devices
