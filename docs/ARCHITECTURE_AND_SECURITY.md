# Pottery App - Architecture and Security Guide

## Table of Contents
- [System Architecture Overview](#system-architecture-overview)
- [Service Relationships](#service-relationships)
- [Security Model](#security-model)
- [Account Types and Roles](#account-types-and-roles)
- [Keys and Certificates](#keys-and-certificates)
- [Environment Setup from Scratch](#environment-setup-from-scratch)
- [Graduating from Dev to Production](#graduating-from-dev-to-production)

---

## System Architecture Overview

The Pottery App is a full-stack mobile application built on Google Cloud Platform with the following components:

```
┌─────────────────────────────────────────────────────────────────┐
│                         End Users                                │
│  (Google Workspace users with managed Google Play access)       │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Google Play Store                             │
│  - App Distribution (internal testing / production)              │
│  - App Signing (re-signs AAB with Play Store key)               │
│  - Managed Google Play (organization-level distribution)        │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Flutter Mobile App (Frontend)                   │
│  - Three flavors: local, dev, prod                               │
│  - Firebase Authentication (Google Sign-In)                      │
│  - HTTP client for backend API calls                            │
│  - Photo capture and upload                                      │
└────┬────────────────────────────────────┬─────────────────────┬─┘
     │                                     │                     │
     │ Auth Token                          │ API Calls           │ File Upload
     ▼                                     ▼                     ▼
┌─────────────────┐  ┌──────────────────────────────┐  ┌────────────────┐
│  Firebase Auth  │  │  Cloud Run (Backend API)     │  │  Cloud Storage │
│  - User mgmt    │  │  - FastAPI Python            │  │  - Photo files │
│  - Google OAuth │  │  - JWT token verification    │  │  - Signed URLs │
│  - ID tokens    │  │  - Business logic            │  │  - Bucket CORS │
└─────────────────┘  └────┬───────────────────┬─────┘  └────────────────┘
                          │                   │
                          │ Metadata          │ File ops
                          ▼                   ▼
                   ┌──────────────────────────────┐
                   │       Firestore DB            │
                   │  - Pottery item metadata      │
                   │  - User profiles              │
                   │  - Photo references           │
                   │  - Deletion requests          │
                   └───────────────────────────────┘
```

---

## Service Relationships

### Google Cloud Platform (GCP)
**Purpose**: Infrastructure and backend services
**Project ID**: `pottery-app-456522` (dev), `pottery-app-prod` (production - future)

**Services Used**:
- **Cloud Run**: Hosts the FastAPI backend container
- **Cloud Storage**: Stores photo files in GCS buckets
- **Firestore**: NoSQL database for pottery item metadata
- **Cloud Build**: Builds Docker images from source
- **Artifact Registry**: Stores Docker images
- **Secret Manager**: Stores service account keys securely

### Firebase
**Purpose**: Authentication and client-side configuration
**Project**: Same as GCP project (`pottery-app-456522`)

**Services Used**:
- **Firebase Authentication**: User authentication via Google Sign-In
- **Firebase Admin SDK**: Backend token verification
- **Firebase Client SDK**: Frontend authentication UI

**Key Concept**: Firebase and Google Cloud are the same project under the hood. Firebase is a developer-friendly layer on top of GCP services.

### Google Play Store
**Purpose**: App distribution and signing
**Account**: Your Google Play Developer account

**Key Functions**:
1. **App Signing**: Play Store re-signs your uploaded AAB with their own key
2. **Distribution**: Manages internal testing, production releases
3. **Managed Google Play**: Organization-level distribution to Workspace users

### Google Workspace
**Purpose**: Organization-level app management
**Admin Account**: Your Workspace admin account

**Integration**: Managed Google Play allows you to distribute private apps to organization users

---

## Security Model

### Authentication Flow

```
1. User opens app → Firebase Auth UI (Google Sign-In)
2. User selects Google account → Firebase returns ID token
3. App includes ID token in Authorization header: "Bearer <token>"
4. Backend receives request → Verifies token with Firebase Admin SDK
5. Token valid → Extracts user_id → Processes request with user scope
6. Token invalid → Returns 401 Unauthorized
```

### Data Isolation

- **User-scoped data**: All pottery items and photos are associated with `user_id`
- **Query filtering**: Backend automatically filters queries by authenticated user
- **Access control**: Users can only access their own data
- **Future admin role**: Admin users will have access to all data for moderation

### Photo Access Control

Photos are stored in Cloud Storage but not publicly accessible:

1. **Storage**: Photos saved to GCS at `items/{item_id}/{photo_id}.jpg`
2. **Signed URLs**: Backend generates time-limited signed URLs (15 min expiration)
3. **Access**: App fetches signed URLs from backend API (requires auth)
4. **Display**: App loads photos using signed URLs

This ensures photos are only accessible to authenticated users via the backend API.

---

## Account Types and Roles

### 1. Your Personal Google Account
**Purpose**: Owner and developer
**Access**: Everything

- GCP Project Owner
- Firebase Project Owner
- Google Play Developer account
- Google Workspace admin (if applicable)

### 2. GCP Service Accounts

#### a. Deployment Service Account
**Email**: `pottery-app-deployer@pottery-app-456522.iam.gserviceaccount.com`
**Purpose**: Automated deployments from local machine
**Permissions**:
- `roles/run.admin` - Deploy to Cloud Run
- `roles/cloudbuild.builds.editor` - Trigger Cloud Build
- `roles/iam.serviceAccountUser` - Act as runtime service account
- `roles/artifactregistry.admin` - Manage Docker images

**Key File**: `~/.gsutil/pottery-app-deployer-456522-key.json` (local only, never commit)

**Created**: Via `gcloud iam service-accounts create` in setup scripts

#### b. Cloud Run Runtime Service Account
**Email**: `pottery-app-sa@pottery-app-456522.iam.gserviceaccount.com`
**Purpose**: Backend API runtime permissions
**Permissions**:
- `roles/datastore.user` - Read/write Firestore
- `roles/storage.objectAdmin` - Read/write Cloud Storage
- `roles/secretmanager.secretAccessor` - Access Secret Manager secrets

**Key File**: Stored in Secret Manager, mounted to Cloud Run container at `/tmp/gcp_key.json`

**Created**: Automatically by Firebase, enhanced with additional roles

#### c. Cloud Build Service Account
**Email**: `[PROJECT_NUMBER]@cloudbuild.gserviceaccount.com`
**Purpose**: Build Docker images and push to Artifact Registry
**Permissions**:
- `roles/artifactregistry.writer` - Push images to registry

**Created**: Automatically by Google Cloud

#### d. Play Console Service Account
**Email**: `play-console-deployer@pottery-app-456522.iam.gserviceaccount.com`
**Purpose**: Automated Play Store uploads (future)
**Permissions**: Configured in Play Console (not GCP IAM)
- View app information
- Manage production releases
- Manage testing track releases

**Key File**: `~/pottery-keystore/play-console-sa-key.json` (local only)

**Created**: Via `gcloud iam service-accounts create`, invited to Play Console

### 3. Firebase Service Account
**Email**: `firebase-adminsdk-xxxxx@pottery-app-456522.iam.gserviceaccount.com`
**Purpose**: Firebase Admin SDK operations
**Permissions**: Full Firebase access

**Created**: Automatically when Firebase is initialized

### 4. End Users
**Authentication**: Firebase Authentication (Google Sign-In)
**Data Access**: Own pottery items and photos only
**No GCP Access**: Users never interact with GCP directly

---

## Keys and Certificates

### 1. Android App Signing Keys

#### Upload Key (Your Keystore)
**File**: `~/pottery-keystore/pottery-release-key.jks`
**Purpose**: Sign AAB before uploading to Play Store
**SHA-1**: Generated from this keystore

```bash
keytool -list -v -keystore ~/pottery-keystore/pottery-release-key.jks -alias pottery-app
```

**Critical**: If you lose this key, you cannot update your app (will need to publish as new app)

#### Play Store App Signing Key
**Managed by**: Google Play Store
**Purpose**: Final app signing after upload (Play App Signing)
**SHA-1**: Different from your upload key, visible in Play Console

**Location**: Play Console > Release > Setup > App signing

**Why two keys?**
- **Upload key**: You control, used for verification during upload
- **App signing key**: Google controls, used for actual app distribution
- Benefit: If your upload key is compromised, Google can issue you a new one without affecting users

### 2. Firebase SHA-1 Fingerprints

Firebase needs to know about BOTH keys:

```
Firebase Console > Project Settings > Your apps > Android app > Add fingerprint
```

**Required fingerprints:**
1. **Upload key SHA-1**: For local development and APK builds
2. **Play Store app signing key SHA-1**: For apps distributed via Play Store

**Consequence of missing Play Store SHA-1**: ApiException: 10 when signing in via Play Store

### 3. GCP Service Account Keys

#### Deployment Key
**File**: `~/.gsutil/pottery-app-deployer-456522-key.json`
**Usage**: Authenticate deployment scripts

```bash
gcloud auth activate-service-account \
  pottery-app-deployer@pottery-app-456522.iam.gserviceaccount.com \
  --key-file=~/.gsutil/pottery-app-deployer-456522-key.json
```

#### Runtime Key (for Signed URLs)
**File**: Stored in Secret Manager as `pottery-app-sa-key`
**Usage**: Backend generates signed URLs for Cloud Storage

```bash
# Created and stored by fix-signed-urls.sh script
gcloud secrets create pottery-app-sa-key \
  --data-file=~/.gsutil/pottery-app-sa-456522-key.json
```

**Mounted**: Cloud Run mounts secret to `/tmp/gcp_key.json`
**Environment**: `GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp_key.json`

### 4. JWT Secret Key
**Purpose**: Sign test JWT tokens (demo/development only)
**File**: Stored in `.env.dev` (never commit)
**Usage**: `/api/test-token` endpoint for testing without Firebase

**Production**: Not used; Firebase handles all authentication

---

## Environment Setup from Scratch

### Overview: Dev vs Production

| Aspect | Development | Production |
|--------|------------|------------|
| **GCP Project** | pottery-app-456522 | pottery-app-prod (new) |
| **Firebase Project** | pottery-app-456522 | pottery-app-prod (new) |
| **Backend URL** | pottery-api-dev-*.run.app | pottery-api-prod-*.run.app |
| **Package Name** | com.pottery.app.dev | com.pottery.app |
| **Play Store Track** | Internal testing | Production |
| **Data** | Test/demo data | Real user data |
| **Billing** | Shared with personal projects | Dedicated |

### Step 1: Create GCP Project

```bash
# Development (already done)
gcloud projects create pottery-app-456522 --name="Pottery App Dev"

# Production (future)
gcloud projects create pottery-app-prod --name="Pottery App Production"

# Set active project
gcloud config set project pottery-app-456522

# Enable billing (required for Cloud Run, Storage, Firestore)
# Go to: https://console.cloud.google.com/billing
```

### Step 2: Initialize Firebase

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize Firebase in GCP project
firebase projects:addfirebase pottery-app-456522

# Enable Authentication
firebase console:open  # Go to Authentication > Sign-in method > Google > Enable
```

### Step 3: Create Service Accounts

```bash
# Set variables
PROJECT_ID="pottery-app-456522"

# 1. Deployment Service Account
gcloud iam service-accounts create pottery-app-deployer \
  --display-name="Deployment Service Account" \
  --project=$PROJECT_ID

# Grant permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:pottery-app-deployer@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:pottery-app-deployer@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:pottery-app-deployer@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:pottery-app-deployer@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.admin"

# Download key
mkdir -p ~/.gsutil
gcloud iam service-accounts keys create ~/.gsutil/pottery-app-deployer-456522-key.json \
  --iam-account=pottery-app-deployer@${PROJECT_ID}.iam.gserviceaccount.com

# 2. Runtime Service Account (created automatically by Firebase)
# Just enhance its permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:pottery-app-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/datastore.user"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:pottery-app-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:pottery-app-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Download key for signed URLs
gcloud iam service-accounts keys create ~/.gsutil/pottery-app-sa-456522-key.json \
  --iam-account=pottery-app-sa@${PROJECT_ID}.iam.gserviceaccount.com
```

### Step 4: Enable GCP APIs

```bash
# Enable required services
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  firestore.googleapis.com \
  storage.googleapis.com \
  secretmanager.googleapis.com \
  firebase.googleapis.com \
  --project=$PROJECT_ID
```

### Step 5: Create Infrastructure

```bash
# 1. Create Cloud Storage bucket
gsutil mb -p $PROJECT_ID -l us-central1 gs://pottery-app-456522-bucket

# Make bucket private (default)
gsutil iam ch allUsers:objectViewer gs://pottery-app-456522-bucket

# Configure CORS for signed URLs
gsutil cors set backend/infrastructure/cors-config.json gs://pottery-app-456522-bucket

# 2. Create Firestore database
gcloud firestore databases create \
  --location=us-central1 \
  --project=$PROJECT_ID

# 3. Create Secret Manager secret for runtime service account key
gcloud secrets create pottery-app-sa-key \
  --data-file=~/.gsutil/pottery-app-sa-456522-key.json \
  --replication-policy="automatic" \
  --project=$PROJECT_ID

# Grant access to runtime service account
gcloud secrets add-iam-policy-binding pottery-app-sa-key \
  --member="serviceAccount:pottery-app-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=$PROJECT_ID
```

### Step 6: Deploy Backend

```bash
# Create environment file
cat > backend/.env.dev << EOF
ENVIRONMENT=development
GCP_PROJECT_ID=pottery-app-456522
GCS_BUCKET_NAME=pottery-app-456522-bucket
FIRESTORE_COLLECTION=pottery_items
FIRESTORE_DATABASE_ID=(default)
SIGNED_URL_EXPIRATION_MINUTES=15
FIREBASE_PROJECT_ID=pottery-app-456522
BUILD_SERVICE_NAME=pottery-api-dev
BUILD_REGION=us-central1
BUILD_REPO_NAME=pottery-app-repo
DEPLOYMENT_SERVICE_ACCOUNT_EMAIL=pottery-app-deployer@pottery-app-456522.iam.gserviceaccount.com
DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE=$HOME/.gsutil/pottery-app-deployer-456522-key.json
CLOUD_RUN_SERVICE_ACCOUNT_EMAIL=pottery-app-sa@pottery-app-456522.iam.gserviceaccount.com
EOF

# Deploy
cd backend
./build_and_deploy.sh --env=dev

# The script automatically:
# 1. Authenticates with deployment service account
# 2. Builds Docker image with Cloud Build
# 3. Pushes to Artifact Registry
# 4. Deploys to Cloud Run
# 5. Configures signed URLs (runs fix-signed-urls.sh)
```

### Step 7: Configure Firebase for Flutter

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for each flavor
cd frontend

# Dev flavor
flutterfire configure \
  --project=pottery-app-456522 \
  --out=lib/firebase_options_dev.dart \
  --platforms=android,ios \
  --android-package-name=com.pottery.app.dev

# Local flavor (uses same Firebase project as dev)
flutterfire configure \
  --project=pottery-app-456522 \
  --out=lib/firebase_options_local.dart \
  --platforms=android,ios \
  --android-package-name=com.pottery.app.local
```

### Step 8: Add Firebase SHA-1 Fingerprints

```bash
# 1. Generate upload key (if not exists)
keytool -genkey -v -keystore ~/pottery-keystore/pottery-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias pottery-app

# 2. Get SHA-1 from upload key
keytool -list -v -keystore ~/pottery-keystore/pottery-release-key.jks \
  -alias pottery-app | grep SHA1

# 3. Add to Firebase Console:
#    Console > Project Settings > Your apps > Android app > Add fingerprint

# 4. After first Play Store upload, get Play Store SHA-1:
#    Play Console > Release > Setup > App signing
#    Copy SHA-1 and add to Firebase (same place)

# 5. Download new google-services.json and place in:
#    frontend/android/app/src/dev/google-services.json
#    frontend/android/app/src/local/google-services.json
```

### Step 9: Build and Deploy Flutter App

```bash
cd frontend

# Local development (connects to local Docker backend)
./scripts/build_dev.sh  # Select option 1

# Dev environment (connects to Cloud Run dev backend)
flutter build appbundle --release --flavor dev \
  --dart-define=API_BASE_URL=https://pottery-api-dev-*.run.app

# Upload to Play Store (manual first time)
# Play Console > Create app > Upload AAB > Internal testing
```

### Step 10: Configure Play Store

1. **Create app** in Play Console
2. **Upload AAB** to internal testing
3. **Get Play Store SHA-1** from Release > Setup > App signing
4. **Add SHA-1 to Firebase** (critical for authentication)
5. **Rebuild and re-upload** AAB with updated google-services.json
6. **Test authentication** on device via Play Store

---

## Graduating from Dev to Production

### The Challenge

Your dev and prod environments use DIFFERENT Firebase projects:
- **Dev**: `pottery-app-456522` with package `com.pottery.app.dev`
- **Prod**: `pottery-app-prod` with package `com.pottery.app`

**This means users authenticate to different Firebase projects and cannot share accounts between environments.**

### Migration Strategy

#### Option 1: Separate User Bases (Recommended)

**Concept**: Dev and prod are completely isolated. Users in dev (testers) are different from prod users (customers).

**Benefits**:
- Clean separation of concerns
- No risk of test data in production
- Independent scaling and billing
- Easier to reason about

**Workflow**:
```
1. Develop and test in dev environment (com.pottery.app.dev)
   - Testers create accounts in pottery-app-456522
   - Test all features with test data

2. When ready for production:
   - Deploy backend to prod Cloud Run
   - Build prod AAB (com.pottery.app)
   - Upload to Play Store production track
   - End users create new accounts in pottery-app-prod
   - No data migration needed
```

**Graduation Steps**:

```bash
# 1. Create production GCP/Firebase project (follow Step 1-5 above)
PROJECT_ID="pottery-app-prod"

# 2. Create production .env file
cat > backend/.env.prod << EOF
ENVIRONMENT=production
GCP_PROJECT_ID=pottery-app-prod
GCS_BUCKET_NAME=pottery-app-prod-bucket
FIRESTORE_COLLECTION=pottery_items
FIRESTORE_DATABASE_ID=(default)
SIGNED_URL_EXPIRATION_MINUTES=15
FIREBASE_PROJECT_ID=pottery-app-prod
BUILD_SERVICE_NAME=pottery-api-prod
BUILD_REGION=us-central1
BUILD_REPO_NAME=pottery-app-repo
DEPLOYMENT_SERVICE_ACCOUNT_EMAIL=pottery-app-deployer@pottery-app-prod.iam.gserviceaccount.com
DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE=$HOME/.gsutil/pottery-app-deployer-prod-key.json
CLOUD_RUN_SERVICE_ACCOUNT_EMAIL=pottery-app-sa@pottery-app-prod.iam.gserviceaccount.com
EOF

# 3. Deploy backend to production
cd backend
./build_and_deploy.sh --env=prod

# 4. Configure Firebase for production Flutter flavor
cd frontend
flutterfire configure \
  --project=pottery-app-prod \
  --out=lib/firebase_options_prod.dart \
  --platforms=android,ios \
  --android-package-name=com.pottery.app

# 5. Build production AAB
flutter build appbundle --release --flavor prod \
  --dart-define=API_BASE_URL=https://pottery-api-prod-*.run.app

# 6. Create NEW app in Play Console for production
#    Name: "Pottery Studio" (without "Dev")
#    Package: com.pottery.app

# 7. Upload to internal testing first, then promote to production

# 8. Get Play Store SHA-1 and add to Firebase (pottery-app-prod)

# 9. Rebuild and upload final production AAB
```

#### Option 2: Data Migration (Advanced)

**Concept**: Migrate user accounts and data from dev to prod.

**When to use**: If your "dev" users are actually your first customers and you want to preserve their data.

**Challenges**:
- Firebase user migration is complex (requires Firebase Admin SDK)
- Cloud Storage files must be copied between buckets
- Firestore data must be exported and imported
- User ID mappings must be maintained

**High-level migration steps**:

```bash
# 1. Export users from dev Firebase
# Use Firebase Admin SDK to export user accounts
# https://firebase.google.com/docs/auth/admin/manage-users#bulk_import_users

# 2. Import users to prod Firebase
# Requires password hashes and user data

# 3. Export Firestore data
gcloud firestore export gs://pottery-app-456522-backup \
  --project=pottery-app-456522

# 4. Import to production Firestore
gcloud firestore import gs://pottery-app-456522-backup \
  --project=pottery-app-prod

# 5. Copy Cloud Storage files
gsutil -m cp -r gs://pottery-app-456522-bucket/* gs://pottery-app-prod-bucket/

# 6. Update user_id references if UIDs changed during migration
# (Requires custom script to remap IDs in Firestore)
```

**Recommendation**: Unless you have real customer data in dev, use Option 1 (separate user bases). It's simpler and cleaner.

#### Option 3: Single Production Project (Alternative Architecture)

**Concept**: Use one Firebase project for both dev and prod, but different package names.

**Structure**:
```
Firebase Project: pottery-app-456522 (same for both)
- Android app 1: com.pottery.app.dev (dev)
- Android app 2: com.pottery.app (prod)

Backend:
- Cloud Run dev: pottery-api-dev-*.run.app
- Cloud Run prod: pottery-api-prod-*.run.app
- Same GCS bucket with environment prefixes: dev/, prod/
- Same Firestore with collection prefixes: dev_pottery_items, prod_pottery_items
```

**Benefits**:
- Single Firebase project to manage
- Easier to share configuration
- Users could theoretically use both apps with same account

**Drawbacks**:
- Shared billing (dev costs affect prod)
- Risk of accidental data mixing
- More complex backend logic (environment-aware collection names)
- Less isolation

---

## Summary: Complete Environment Flow

### Development Environment
```
Developer → Build locally → Docker → Local backend → Firestore dev
                                                    ↓
Developer → Build dev AAB → Upload to Play Store Internal Testing
                                    ↓
Testers → Install from Play Store → pottery-api-dev → Firestore dev
                                    ↓
                          Firebase Auth (pottery-app-456522)
```

### Production Environment (Future)
```
Developer → Build prod AAB → Upload to Play Store Production
                                    ↓
End Users → Install from Play Store → pottery-api-prod → Firestore prod
                                    ↓
                          Firebase Auth (pottery-app-prod)
```

### Key Takeaways

1. **Dev and prod are ISOLATED**: Different projects, different users, different data
2. **Google Play re-signs apps**: Must add Play Store SHA-1 to Firebase
3. **Service accounts are environment-specific**: Create separate ones for prod
4. **Graduation = Redeployment**: Not migration; prod is built fresh from same code
5. **Test in dev first**: Use internal testing track, validate everything, then deploy prod

---

## Related Documentation

- [Deployment Guide](DEPLOYMENT_GUIDE.md) - Step-by-step deployment instructions
- [Firebase Multi-Environment Setup](FIREBASE_MULTI_ENV_SETUP.md) - Detailed Firebase configuration
- [Backend README](../backend/README.md) - Backend architecture and local development

## Support Resources

- [Google Cloud Console](https://console.cloud.google.com/)
- [Firebase Console](https://console.firebase.google.com/)
- [Google Play Console](https://play.google.com/console)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
