# Deploy to Google Play Store

Complete guide for deploying the Pottery Studio app to Google Play Store for internal testing and production distribution.

## Overview

This guide covers deploying both **test/development** and **production** versions of the Pottery Studio app to Google Play Store.

**Key Differences:**

| Aspect | Test/Dev Build | Production Build |
|--------|---------------|------------------|
| **Package** | `com.pottery.app.dev` | `com.pottery.app` |
| **Backend** | Cloud Run Dev | Cloud Run Prod |
| **Build Script** | `./build_dev.sh appbundle` | `./build_prod.sh appbundle` |
| **Version Increment** | PATCH (1.0.0 → 1.0.1) | MINOR (1.0.0 → 1.1.0) |
| **Security** | Standard | Code obfuscation + split debug symbols |
| **Confirmation** | None | Required before build |
| **AAB Output** | `app-dev-release.aab` | `app-prod-release.aab` |

---

## Prerequisites

### Required Accounts & Tools

- [x] Google Play Developer account ($25 one-time fee)
- [x] Google Workspace admin access (for managed distribution)
- [x] `flutter`, `python3`, `gcloud`, `firebase` CLIs installed
- [x] Firebase project configured (dev: `pottery-app-456522`)
- [ ] Production Firebase project (optional: `pottery-app-prod`)

### Repository Setup

```bash
# Ensure you're in the frontend directory
cd /path/to/pottery-backend/frontend

# Verify build scripts are executable
ls -l scripts/build_*.sh
```

---

## Part 1: One-Time Setup

### Step 1: Create Release Keystore

**⚠️ CRITICAL:** If you lose this password, you cannot update your app!

```bash
# Create secure directory for credentials
mkdir -p ~/pottery-keystore
cd ~/pottery-keystore

# Generate ONE strong password (16+ characters)
# Store in password manager (1Password, LastPass, etc.)
# Example format: "MyP0ttery$ecure#3y2024!" (create your own!)

# Generate release keystore
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

**Note:** Your `frontend/android/app/build.gradle.kts` is already configured to use this keystore.

### Step 2: Enable Google Play Developer API

```bash
# Authenticate as your user account
gcloud auth login

# List projects and set active one
gcloud projects list
gcloud config set project pottery-app-456522  # Use your project ID

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

### Step 3: Create App in Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Click **Create app**
3. Fill in details:
   - **App name**: Pottery Studio Dev (or Pottery Studio for prod)
   - **Default language**: English (United States)
   - **App or game**: App
   - **Free or paid**: Free
4. Click **Create app**

**Note:** You can create multiple apps (one for dev, one for prod) with different package names.

### Step 4: Invite Service Account to Play Console

1. In [Play Console](https://play.google.com/console), navigate to **Users and permissions**
2. Click **Invite new users**
3. Enter service account email: `play-console-deployer@pottery-app-456522.iam.gserviceaccount.com`
4. Assign permissions:
   - ✅ **View app information and download bulk reports**
   - ✅ **Manage production releases**
   - ✅ **Manage testing track releases**
5. Click **Send invitation**

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

---

## Part 2: Building for Play Store

### Option A: Development/Test Build

**Use Case:** Internal testing with development backend

```bash
cd /path/to/pottery-backend/frontend/scripts

# Build dev AAB with automatic version increment
./build_dev.sh appbundle
```

**What this does:**
- ✅ Auto-increments **PATCH** version (1.0.0 → 1.0.1)
- ✅ Auto-increments build number (+1, +2, +3...)
- ✅ Updates `pubspec.yaml` automatically
- ✅ Builds AAB with dev backend URL
- ✅ Package: `com.pottery.app.dev`
- ✅ Backend: `https://pottery-api-dev.run.app`

**Output:** `frontend/build/app/outputs/bundle/devRelease/app-dev-release.aab`

### Option B: Production Build

**Use Case:** Production release with production backend

```bash
cd /path/to/pottery-backend/frontend/scripts

# Build production AAB with automatic version increment
./build_prod.sh appbundle
```

**What this does:**
- ✅ Auto-increments **MINOR** version (1.0.0 → 1.1.0)
- ✅ Auto-increments build number (+1, +2, +3...)
- ✅ **Requires confirmation prompt** (production safety check)
- ✅ Updates `pubspec.yaml` automatically
- ✅ Includes **code obfuscation** & **split debug symbols**
- ✅ Package: `com.pottery.app`
- ✅ Backend: `https://pottery-api-prod.run.app`

**Output:** `frontend/build/app/outputs/bundle/prodRelease/app-prod-release.aab`

**Security Features:**
- 🔒 Code obfuscation (makes reverse engineering difficult)
- 🔒 Split debug symbols (stored separately for crash analysis)
- 🔒 Localhost URL warnings (prevents accidental dev URLs)

### Custom Backend URL (Optional)

Override the default backend URL:

```bash
# Development build with custom URL
API_BASE_URL=https://pottery-api-dev-custom.run.app ./build_dev.sh appbundle

# Production build with custom URL
API_BASE_URL=https://pottery-api-prod-custom.run.app ./build_prod.sh appbundle
```

---

## Part 3: Upload to Play Store

### Manual Upload (Recommended for First Time)

**For Development/Test Build:**

1. In Play Console, go to **Testing > Internal testing**
2. Click **Create new release**
3. Upload the AAB: `frontend/build/app/outputs/bundle/devRelease/app-dev-release.aab`
4. Fill in release notes:
   ```
   Development release for internal testing
   - Pottery item tracking and organization
   - Photo upload and management
   - Firebase authentication
   - Item measurements and notes
   ```
5. Click **Review release** → **Start rollout to Internal testing**

**For Production Build:**

1. In Play Console, select your **production app** (`com.pottery.app`)
2. Go to **Testing > Internal testing** (validate first!)
3. Upload the AAB: `frontend/build/app/outputs/bundle/prodRelease/app-prod-release.aab`
4. Fill in release notes
5. **Test thoroughly** with internal testers
6. When validated, navigate to **Production** track
7. Click **Promote release** from internal testing
8. Review and confirm production rollout

### Automated Upload (Subsequent Releases)

**Development Build:**

```bash
cd /path/to/pottery-backend

# Set environment variables
export GOOGLE_APPLICATION_CREDENTIALS=~/pottery-keystore/play-console-sa-key.json
export PACKAGE_NAME=com.pottery.app.dev
export BUILD_FILE=frontend/build/app/outputs/bundle/devRelease/app-dev-release.aab
export PLAY_TRACK=internal

# Run upload script
python3 scripts/deploy/upload-to-play-store.py
```

**Production Build:**

```bash
cd /path/to/pottery-backend

# Set environment variables
export GOOGLE_APPLICATION_CREDENTIALS=~/pottery-keystore/play-console-sa-key.json
export PACKAGE_NAME=com.pottery.app
export BUILD_FILE=frontend/build/app/outputs/bundle/prodRelease/app-prod-release.aab
export PLAY_TRACK=internal  # Start with internal, then promote manually

# Run upload script
python3 scripts/deploy/upload-to-play-store.py
```

**⚠️ Important:** Automated scripts upload to **internal** track only. Manually promote to production in Play Console UI after thorough testing.

### Comprehensive Deployment Script

```bash
# Development deployment
./scripts/deploy/build-and-deploy-play-store.sh \
  --flavor dev \
  --track internal

# Production deployment (to internal track for validation)
./scripts/deploy/build-and-deploy-play-store.sh \
  --flavor prod \
  --track internal
```

---

## Part 4: Firebase Authentication Setup

### Critical: Add Play Store Signing Certificate

**Problem:** After uploading to Play Store, Google Sign-In fails with "ApiException: 10"

**Cause:** Google Play re-signs your app with their own signing key

**Solution:** Add Play Store's SHA-1 fingerprint to Firebase

**Steps:**

1. **Get Play Store signing certificate:**
   - Go to [Play Console](https://play.google.com/console) > Your app
   - Navigate to **Release > Setup > App signing**
   - Under "App signing key certificate", copy the **SHA-1 fingerprint**

2. **Add to Firebase:**
   - Go to [Firebase Console](https://console.firebase.google.com/) > Your project
   - **Project settings** > Scroll to "Your apps"
   - Find your Android app (e.g., `com.pottery.app.dev` or `com.pottery.app`)
   - Click **Add fingerprint**
   - Paste the Play Store SHA-1 fingerprint
   - Click **Save**

3. **Download new config and rebuild:**
   ```bash
   # Download new google-services.json from Firebase Console
   # Place in: frontend/android/app/src/{flavor}/google-services.json

   # Rebuild AAB with new Firebase config
   cd frontend/scripts
   ./build_prod.sh appbundle  # or ./build_dev.sh appbundle

   # Upload new version to Play Store
   ```

**Important:** You need **TWO SHA-1 fingerprints** in Firebase:
- 🔑 Your upload key SHA-1 (for local development/testing)
- 🔑 Play Store's app signing key SHA-1 (for production distribution)

---

## Part 5: Managed Google Play Distribution

### Enable Managed Google Play in Workspace

**Option A: Through Web and Mobile Apps**
1. Go to [Google Workspace Admin Console](https://admin.google.com)
2. Navigate to **Apps > Web and mobile apps**
3. Click **Add app > Add from Google Play Store**
4. This enables Managed Google Play

**Option B: Through Device Management**
1. Go to **Devices > Mobile & endpoints > Settings > Universal**
2. Look for Android settings or Enterprise enrollment
3. Follow prompts to enable Android enterprise management
4. This automatically enables Managed Google Play

**Option C: Direct Managed Google Play Setup**
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

**Through Web and Mobile Apps (Most Common):**
1. In [Admin Console](https://admin.google.com), go to **Apps > Web and mobile apps**
2. Click **Add app > Add from Google Play Store**
3. Search for "Pottery Studio Dev" (or your app name)
4. Click on your app and click **Select**
5. Configure installation settings:
   - **Installation policy**: "Allow users to install" or "Force install"
   - **Users**: Select organizational units or groups
6. Click **Save**

### Users Install the App

Selected users will see your app in Google Play Store under **"Work apps"** section and can install it directly.

---

## Part 6: Version Management

### Semantic Versioning Strategy

Follow this pattern in `frontend/pubspec.yaml`:

```yaml
version: MAJOR.MINOR.PATCH+BUILD_NUMBER
```

**Examples:**
- `1.0.0+1` - Initial release
- `1.0.1+2` - Bug fix (dev build)
- `1.1.0+3` - New feature (production build)
- `2.0.0+4` - Breaking change

**Increment Rules:**
- **BUILD_NUMBER**: Every Play Store upload (required)
- **PATCH**: Bug fixes (dev builds auto-increment)
- **MINOR**: New features (prod builds auto-increment)
- **MAJOR**: Breaking changes (manual)

### Automated Version Management

The build scripts handle versioning automatically:

**Development builds (`build_dev.sh appbundle`):**
- Auto-increment PATCH: `1.0.0 → 1.0.1`
- Auto-increment build number: `+1, +2, +3...`
- Updates `pubspec.yaml` automatically

**Production builds (`build_prod.sh appbundle`):**
- Auto-increment MINOR: `1.0.0 → 1.1.0`
- Auto-increment build number: `+1, +2, +3...`
- Requires confirmation prompt
- Updates `pubspec.yaml` automatically

### Manual Version Update (Advanced)

```bash
# 1. Edit version in frontend/pubspec.yaml
# Change: version: 1.0.0+1
# To:     version: 2.0.0+2  # Major version bump

# 2. Build with explicit version
cd frontend
flutter build appbundle --release \
  --flavor prod \
  --build-name=2.0.0 \
  --build-number=2

# 3. Upload to Play Store (manual or automated)
```

---

## Troubleshooting

### Build Errors

**"No matching client found for package name"**
- Firebase `google-services.json` doesn't have your package configured
- **Solution:**
  1. Add the app to Firebase Console
  2. Download new `google-services.json`
  3. Place in `frontend/android/app/src/{flavor}/google-services.json`

**"Unresolved reference: util"**
- Missing imports in `build.gradle.kts`
- **Solution:** Already fixed - imports are at top of file

**"Keystore file not found"**
- Keystore not created or wrong path
- **Solution:** Follow Step 1 to create keystore at `~/pottery-keystore/pottery-release-key.jks`

### Upload Errors

**"Service account permission denied"**
- Service account not properly invited or API access not active
- **Solution:**
  - Wait up to 24 hours after inviting service account
  - Verify permissions in Play Console > Users and permissions
  - Check service account email matches exactly

**"Package name mismatch"**
- App being uploaded doesn't match app in Play Console
- **Solution:**
  - Verify package name: `com.pottery.app.dev` vs `com.pottery.app`
  - Create separate apps in Play Console for each package

**"Version code must be greater than previous upload"**
- Build number not incremented
- **Solution:** Build scripts auto-increment, but if manual:
  ```bash
  # Increment build number in pubspec.yaml
  # Or use build script which does this automatically
  ./build_prod.sh appbundle
  ```

### Distribution Issues

**Users can't find app**
- App not assigned to their organizational unit
- **Solution:**
  1. Verify app is assigned in Workspace Admin Console
  2. Check app is published to internal/production track
  3. Users should look in "Work apps" section of Play Store

**"ApiException: 10" when signing in**
- SHA certificate fingerprint mismatch (see Part 4)
- **Solution:** Add Play Store's app signing certificate to Firebase

**App crashes after Play Store installation**
- Missing or incorrect Firebase configuration
- **Solution:**
  1. Ensure `google-services.json` is in correct flavor directory
  2. Verify SHA-1 fingerprints in Firebase (both upload and Play Store)
  3. Check backend URL is correct for the build flavor

### Performance Issues

**Large AAB file size**
- Web/asset bloat
- **Solution:**
  ```bash
  # Analyze bundle size
  flutter build appbundle --analyze-size

  # Remove unused assets
  flutter clean
  flutter pub get
  flutter build appbundle --release
  ```

**Slow build times**
- Gradle cache issues
- **Solution:**
  ```bash
  cd android
  ./gradlew clean
  cd ..
  flutter clean
  flutter build appbundle
  ```

---

## Deployment Workflows

### Development Workflow (Current)

```bash
# 1. Make changes locally
cd frontend/scripts
./build_dev.sh  # Test locally

# 2. Build for Play Store testing
./build_dev.sh appbundle

# 3. Upload to internal testing track
# (Manual upload or automated script)

# 4. Team members test "Pottery Studio Dev" app

# 5. Iterate based on feedback
```

### Production Workflow

```bash
# 1. Validate thoroughly in dev environment

# 2. Build production AAB
cd frontend/scripts
./build_prod.sh appbundle

# 3. Upload to internal track FIRST
# Manual upload or automated script to internal track

# 4. Small group validates production environment
# Test authentication, API calls, photo uploads

# 5. Promote to production track
# In Play Console: Production > Promote release

# 6. Distribute to all users via managed Google Play
```

### Emergency Rollback

```bash
# In Play Console:
# 1. Go to Production track
# 2. Click "View releases"
# 3. Find previous working version
# 4. Click "Re-activate" to rollback
```

---

## Environment Structure Summary

| Environment | Firebase Project | Package | Backend | Use Case |
|------------|-----------------|---------|---------|----------|
| **Local** | pottery-app-456522 | com.pottery.app.local | localhost:8000 | Local dev |
| **Dev/Testing** | pottery-app-456522 | com.pottery.app.dev | pottery-api-dev | Internal testing |
| **Production** | pottery-app-prod* | com.pottery.app | pottery-api-prod | End users |

*pottery-app-prod needs to be created for production deployment

---

## Complete Deployment Checklist

### Pre-Deployment
- [ ] Release keystore created and backed up
- [ ] Service account invited to Play Console (wait 24 hours)
- [ ] App created in Play Console
- [ ] Firebase project configured
- [ ] Backend API deployed and tested
- [ ] Build scripts tested locally

### Development Release
- [ ] Run `./build_dev.sh appbundle`
- [ ] Upload AAB to internal testing track
- [ ] Add Play Store SHA-1 to Firebase
- [ ] Download new `google-services.json`
- [ ] Rebuild and re-upload with new Firebase config
- [ ] Test authentication and core features
- [ ] Gather feedback from internal testers

### Production Release
- [ ] Thoroughly validate in dev environment
- [ ] Run `./build_prod.sh appbundle`
- [ ] Confirm production backend URL
- [ ] Upload to internal track first
- [ ] Test with small group on internal track
- [ ] Verify authentication with production backend
- [ ] Test photo uploads and storage
- [ ] Add Play Store SHA-1 to Firebase (if new app)
- [ ] Promote to production track
- [ ] Configure managed Google Play distribution
- [ ] Monitor for crashes and errors
- [ ] Prepare rollback plan

---

## Related Documentation

- **[Build Scripts Reference](../reference/build-scripts.md)** - Detailed script documentation
- **[Build and Deploy Guide](./build-and-deploy.md)** - Multi-platform build instructions
- **[Multi-App System](../explanation/multi-app-system.md)** - Architecture explanation
- **[Scripts Deployment Guide](/scripts/DEPLOYMENT_GUIDE.md)** - Complete reference guide
- **[Backend Production Setup](../../../backend/docs/how-to/setup-production.md)** - Backend deployment

## Support Resources

- [Google Play Console](https://play.google.com/console)
- [Workspace Admin Console](https://admin.google.com)
- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Play Store Publishing Checklist](https://developer.android.com/distribute/best-practices/launch/launch-checklist)

---

**Next Steps:**
1. ✅ Complete one-time setup (Steps 1-5)
2. ✅ Build dev AAB for internal testing
3. ✅ Upload and configure Firebase authentication
4. ✅ Test with team members
5. ⏳ Build production AAB when ready
6. ⏳ Promote to production after validation
