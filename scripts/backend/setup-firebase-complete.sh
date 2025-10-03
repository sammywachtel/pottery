#!/bin/bash

# Enhanced Pottery App Firebase Setup Script
# Creates production environment, adds web/android apps, and extracts all config values
# Run this script to get complete Firebase configuration automatically

set -euo pipefail

# Validate script is run from correct directory
if [[ ! -f "setup-firebase-complete.sh" ]] || [[ ! -d "../../frontend/lib/src/config" ]]; then
    echo -e "\033[0;31m❌ Error: This script must be run from the backend/scripts/ directory\033[0m"
    echo "Current directory: $(pwd)"
    echo "Expected directory structure:"
    echo "  pottery-backend/"
    echo "  ├── backend/scripts/  ← Run script from here"
    echo "  └── frontend/lib/src/config/"
    exit 1
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
DEV_PROJECT_ID="pottery-app-456522"
PROD_PROJECT_ID="pottery-app-prod"
REGION="us-central1"
BUCKET_LOCATION="us-central1"

# App configurations
WEB_APP_NAME="pottery-frontend"
# Android package IDs for different flavors
ANDROID_PACKAGE_DEV="com.pottery.app.dev"
ANDROID_PACKAGE_LOCAL="com.pottery.app.local"
ANDROID_PACKAGE_PROD="com.pottery.app"
# iOS bundle IDs for different flavors (matching Android)
IOS_BUNDLE_DEV="com.pottery.app.dev"
IOS_BUNDLE_LOCAL="com.pottery.app.local"
IOS_BUNDLE_PROD="com.pottery.app"

# Firebase configuration storage
DEV_CONFIG_FILE="firebase_config_dev.json"
PROD_CONFIG_FILE="firebase_config_prod.json"

# Frontend configuration paths
FRONTEND_CONFIG_DIR="../../frontend/lib/src/config"
ENV_FIREBASE_OPTIONS="$FRONTEND_CONFIG_DIR/firebase_options_env.dart"

# APIs to enable
REQUIRED_APIS=(
    "firebase.googleapis.com"
    "firestore.googleapis.com"
    "firebasestorage.googleapis.com"
    "storage.googleapis.com"
    "storage-api.googleapis.com"
    "storage-component.googleapis.com"
    "people.googleapis.com"
    "firebasehosting.googleapis.com"
    "firebaseinstallations.googleapis.com"
    "firebaserules.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "serviceusage.googleapis.com"
    "identitytoolkit.googleapis.com"
)

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

highlight() {
    echo -e "${PURPLE}🎯 $1${NC}"
}

# Check if required tools are installed
check_prerequisites() {
    log "Checking prerequisites..."

    if ! command -v gcloud &> /dev/null; then
        error "gcloud CLI is not installed. Please install Google Cloud SDK."
        exit 1
    fi

    if ! command -v firebase &> /dev/null; then
        error "Firebase CLI is not installed. Please install: npm install -g firebase-tools"
        exit 1
    fi

    # Check if authenticated with Firebase
    if ! firebase projects:list &> /dev/null; then
        warning "Not authenticated with Firebase CLI. Running firebase login..."
        firebase login
    fi

    # Check if authenticated with gcloud
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 > /dev/null; then
        error "Not authenticated with gcloud. Run: gcloud auth login"
        exit 1
    fi

    success "Prerequisites check passed"
}

# Get billing account from dev project
get_billing_account() {
    log "Getting billing account from dev project..."

    DEV_BILLING_ACCOUNT=$(gcloud billing projects describe $DEV_PROJECT_ID --format="value(billingAccountName)" 2>/dev/null || echo "")

    if [[ -z "$DEV_BILLING_ACCOUNT" ]]; then
        warning "Could not get billing account from dev project. You'll need to set this manually."
        echo "Available billing accounts:"
        gcloud billing accounts list --format="table(name,displayName,open)"
        read -p "Enter billing account ID (accounts/XXXXXX-XXXXXX-XXXXXX): " DEV_BILLING_ACCOUNT
    fi

    success "Using billing account: $DEV_BILLING_ACCOUNT"
}

# Create new GCP project
create_project() {
    log "Creating new GCP project: $PROD_PROJECT_ID..."

    if gcloud projects describe $PROD_PROJECT_ID &> /dev/null; then
        warning "Project $PROD_PROJECT_ID already exists. Skipping creation."
        return 0
    fi

    # Create project
    gcloud projects create $PROD_PROJECT_ID \
        --name="Pottery App Production" \
        --set-as-default

    # Link billing account
    if [[ -n "$DEV_BILLING_ACCOUNT" ]]; then
        gcloud billing projects link $PROD_PROJECT_ID \
            --billing-account=${DEV_BILLING_ACCOUNT#accounts/}
    fi

    success "Created project: $PROD_PROJECT_ID"
}

# Enable required APIs
enable_apis() {
    local project_id=$1
    log "Enabling required APIs for $project_id..."

    gcloud config set project $project_id

    for api in "${REQUIRED_APIS[@]}"; do
        log "Enabling $api..."
        gcloud services enable $api --project=$project_id
    done

    success "All APIs enabled for $project_id"
}

# Add Firebase to GCP project
add_firebase_to_project() {
    local project_id=$1
    log "Adding Firebase to project: $project_id..."

    # This adds Firebase to an existing GCP project
    firebase projects:addfirebase $project_id || {
        warning "Firebase may already be enabled for $project_id"
    }

    success "Firebase added to $project_id"
}

# Create or reuse web app in Firebase project
create_web_app() {
    local project_id=$1
    local app_name="$2"

    log "Checking for existing web app '$app_name' in project $project_id..."

    # Check if web app with this display name already exists by trying to extract config
    if firebase apps:sdkconfig web --project=$project_id --out="/tmp/web_check_${project_id}.json" 2>/dev/null; then
        # If we can extract config, at least one web app exists
        rm -f "/tmp/web_check_${project_id}.json"
        success "Reusing existing web app in $project_id"
        return 0
    fi

    # If we get here, no web app exists
    log "Creating new web app '$app_name' in project $project_id..."
    firebase apps:create web "$app_name" --project=$project_id
    success "Created web app '$app_name' in $project_id"
}

# Create or reuse Android app in Firebase project
create_android_app() {
    local project_id=$1
    local package_name="$2"
    local app_name="$3"

    log "Checking for existing Android app '$package_name' in project $project_id..."

    # Check if Android app with this package name already exists by extracting config
    if firebase apps:sdkconfig android --project=$project_id --out="/tmp/android_check_${project_id}.json" 2>/dev/null; then
        local existing_package=$(grep -o '"package_name": "[^"]*"' "/tmp/android_check_${project_id}.json" | cut -d'"' -f4)
        rm -f "/tmp/android_check_${project_id}.json"

        if [[ "$existing_package" == "$package_name" ]]; then
            success "Reusing existing Android app '$package_name' in $project_id"
            return 0
        fi
    fi

    # If we get here, no matching Android app exists
    log "Creating new Android app '$app_name' in project $project_id..."
    # Create Android app with proper syntax: platform, display-name, --package-name
    firebase apps:create android "$app_name" --package-name="$package_name" --project=$project_id
    success "Created Android app '$app_name' in $project_id"
}

# Create or reuse iOS app in Firebase project (for macOS support)
create_ios_app() {
    local project_id=$1
    local bundle_id="$2"
    local app_name="$3"

    log "Checking for existing iOS app '$bundle_id' in project $project_id..."

    # Check if iOS app with this bundle ID already exists
    if firebase apps:sdkconfig ios --project=$project_id --out="/tmp/ios_check_${project_id}.plist" 2>/dev/null; then
        local existing_bundle=$(grep -A1 "<key>BUNDLE_ID</key>" "/tmp/ios_check_${project_id}.plist" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
        rm -f "/tmp/ios_check_${project_id}.plist"

        if [[ "$existing_bundle" == "$bundle_id" ]]; then
            success "Reusing existing iOS app '$bundle_id' in $project_id"
            return 0
        fi
    fi

    # If we get here, no matching iOS app exists
    log "Creating new iOS app '$app_name' in project $project_id..."
    # Create iOS app with proper syntax: platform, display-name, --bundle-id
    firebase apps:create ios "$app_name" --bundle-id="$bundle_id" --project=$project_id
    success "Created iOS app '$app_name' in $project_id"
}

# Configure macOS Info.plist with iOS client ID
configure_macos_for_ios() {
    local project_id=$1
    local bundle_id=$2

    log "Configuring macOS for iOS app '$bundle_id'..."

    # Download iOS config
    local ios_config="/tmp/GoogleService-Info-${bundle_id}.plist"
    firebase apps:sdkconfig ios --project=$project_id --out="$ios_config" 2>/dev/null || {
        warning "Could not download iOS config for $bundle_id"
        return 1
    }

    # Extract CLIENT_ID from plist
    local ios_client_id=$(grep -A1 "<key>CLIENT_ID</key>" "$ios_config" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')

    if [[ -n "$ios_client_id" ]]; then
        # Update macOS Info.plist
        local macos_plist="$SCRIPT_DIR/../../frontend/macos/Runner/Info.plist"

        if [[ -f "$macos_plist" ]]; then
            # Create backup
            cp "$macos_plist" "$macos_plist.backup"

            # Check if GIDClientID already exists
            if grep -q "<key>GIDClientID</key>" "$macos_plist"; then
                # Update existing GIDClientID
                sed -i '' "/<key>GIDClientID<\/key>/,/<\/string>/ s|<string>[^<]*</string>|<string>$ios_client_id</string>|" "$macos_plist"
            else
                # Add GIDClientID before closing </dict>
                sed -i '' "/<\/dict>/i\\
\\	<key>GIDClientID</key>\\
\\	<string>$ios_client_id</string>" "$macos_plist"
            fi

            # Update or add URL scheme
            local reversed_id=$(echo "$ios_client_id" | sed 's/\.apps\.googleusercontent\.com//' | sed 's/\(.*\)-\(.*\)/com.googleusercontent.apps.\1-\2/')

            # Check if CFBundleURLTypes exists
            if grep -q "<key>CFBundleURLTypes</key>" "$macos_plist"; then
                # Update existing URL scheme
                sed -i '' "/<string>com\.googleusercontent\.apps\.[^<]*<\/string>/ s|<string>[^<]*</string>|<string>$reversed_id</string>|" "$macos_plist"
            else
                # Add URL scheme before closing </dict>
                sed -i '' "/<\/dict>/i\\
\\	<key>CFBundleURLTypes</key>\\
\\	<array>\\
\\		<dict>\\
\\			<key>CFBundleURLName</key>\\
\\			<string>REVERSED_CLIENT_ID</string>\\
\\			<key>CFBundleURLSchemes</key>\\
\\			<array>\\
\\				<string>$reversed_id</string>\\
\\			</array>\\
\\		</dict>\\
\\	</array>" "$macos_plist"
            fi

            success "macOS configured with iOS client ID: $ios_client_id"
        else
            warning "macOS Info.plist not found at $macos_plist"
        fi
    else
        warning "Could not extract CLIENT_ID from iOS config"
    fi

    # Clean up
    rm -f "$ios_config"
}

# Extract Firebase configuration
extract_firebase_config() {
    local project_id=$1
    local config_file=$2

    log "Extracting Firebase configuration for $project_id..."

    # Get the first available web app automatically (no user interaction)
    local web_apps=$(firebase apps:list web --project=$project_id --format=json 2>/dev/null)
    local first_app_id=$(echo "$web_apps" | grep -o '"appId": "[^"]*"' | head -n1 | cut -d'"' -f4)

    if [[ -n "$first_app_id" ]]; then
        log "Using web app: $first_app_id"
        firebase apps:sdkconfig web "$first_app_id" --project=$project_id --out="$config_file" || {
            error "Failed to extract Firebase config for $project_id"
            return 1
        }
    else
        # Fallback to old method if app ID extraction fails
        firebase apps:sdkconfig web --project=$project_id --out="$config_file" || {
            error "Failed to extract Firebase config for $project_id"
            return 1
        }
    fi

    success "Firebase config extracted to $config_file"
}

# Create or reuse OAuth client automatically
create_oauth_client_auto() {
    local project_id=$1

    log "Checking for existing OAuth 2.0 client for $project_id..."

    # Check if we already have an OAuth client file
    if [[ -f "oauth_client_${project_id}.txt" ]]; then
        local existing_client_id=$(cat "oauth_client_${project_id}.txt")
        log "Found existing OAuth client file: $existing_client_id"

        # Verify the client still exists in the project
        if gcloud iam oauth-clients describe "$existing_client_id" --project=$project_id >/dev/null 2>&1; then
            success "Reusing existing OAuth client: $existing_client_id"
            return 0
        else
            warning "OAuth client in file no longer exists, will create new one"
            rm -f "oauth_client_${project_id}.txt"
        fi
    fi

    # Check for existing OAuth clients in the project
    local existing_clients=$(gcloud iam oauth-clients list --project=$project_id --format="value(name)" 2>/dev/null | grep "pottery-oauth" | head -n1)

    if [[ -n "$existing_clients" ]]; then
        local client_id=$(echo "$existing_clients" | sed 's|.*/||')
        success "Found and reusing existing OAuth client: $client_id"
        echo "$client_id" > "oauth_client_${project_id}.txt"
        return 0
    fi

    log "Creating new OAuth 2.0 client for $project_id..."

    # Generate a unique OAuth client name
    local client_name="pottery-oauth-client-$(date +%s)"

    # Create OAuth client for web
    local oauth_result=$(gcloud iam oauth-clients create \
        --project=$project_id \
        --display-name="$client_name" \
        --type=web \
        --allowed-origins="http://localhost:9102,http://127.0.0.1:9102,https://$project_id.web.app" \
        --allowed-redirect-uris="http://localhost:9102/__/auth/handler,http://127.0.0.1:9102/__/auth/handler,https://$project_id.web.app/__/auth/handler" \
        --format="value(name)" 2>/dev/null || echo "")

    if [[ -n "$oauth_result" ]]; then
        local client_id=$(echo "$oauth_result" | sed 's|.*/||')
        success "Created OAuth client: $client_id"
        echo "$client_id" > "oauth_client_${project_id}.txt"
    else
        warning "OAuth client creation requires manual setup in Google Cloud Console"
        create_oauth_client_manual "$project_id"
    fi
}

# Manual OAuth client instructions
create_oauth_client_manual() {
    local project_id=$1

    warning "OAuth client setup requires manual configuration:"
    echo ""
    echo "🔗 URL: https://console.cloud.google.com/apis/credentials?project=$project_id"
    echo ""
    echo "📋 Steps:"
    echo "1. Click 'Create Credentials' → 'OAuth 2.0 Client IDs'"
    echo "2. Choose 'Web application'"
    echo "3. Add these Authorized JavaScript origins:"
    echo "   - http://localhost:9102"
    echo "   - http://127.0.0.1:9102"
    echo "   - https://$project_id.web.app"
    echo "4. Add these Authorized redirect URIs:"
    echo "   - http://localhost:9102/__/auth/handler"
    echo "   - http://127.0.0.1:9102/__/auth/handler"
    echo "   - https://$project_id.web.app/__/auth/handler"
    echo ""
}

# Create Cloud Storage bucket
create_storage_bucket() {
    local project_id=$1
    log "Creating Cloud Storage bucket for $project_id..."

    # Use project-id-bucket format to avoid domain verification requirements
    local bucket_name="${project_id}-bucket"

    # Check if bucket exists
    if gsutil ls -b gs://$bucket_name &> /dev/null; then
        warning "Bucket $bucket_name already exists. Skipping creation."
        return 0
    fi

    # Create bucket
    gsutil mb -p $project_id -l $BUCKET_LOCATION gs://$bucket_name

    # Set up CORS for web access
    cat > cors_${project_id}.json << EOF
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"],
    "maxAgeSeconds": 3600
  }
]
EOF

    gsutil cors set cors_${project_id}.json gs://$bucket_name
    rm cors_${project_id}.json

    success "Created storage bucket: $bucket_name"
}

# Create Firestore database
create_firestore_database() {
    local project_id=$1
    log "Creating Firestore database for $project_id..."

    # Check if database already exists
    if gcloud firestore databases describe --project=$project_id &> /dev/null; then
        warning "Firestore database already exists for $project_id"
        return 0
    fi

    # Create Firestore database in Native mode
    gcloud firestore databases create \
        --project=$project_id \
        --location=$REGION \
        --type=firestore-native

    success "Created Firestore database for $project_id"
}

# Configure service account permissions for backend API
configure_service_account_permissions() {
    local project_id=$1
    log "Configuring service account permissions for $project_id..."

    # Service account name pattern
    local service_account="pottery-app-sa@$project_id.iam.gserviceaccount.com"

    # Check if service account exists - create if not
    if ! gcloud iam service-accounts describe "$service_account" --project="$project_id" &> /dev/null; then
        log "Creating service account: $service_account"
        gcloud iam service-accounts create pottery-app-sa \
            --project="$project_id" \
            --display-name="Pottery App Backend Runtime" \
            --description="Service account used by the backend API for Cloud Storage, Firestore, and Firebase access"
        success "Created service account: $service_account"
    else
        log "Service account already exists: $service_account"
    fi

    log "Granting Firestore access..."
    gcloud projects add-iam-policy-binding "$project_id" \
        --member="serviceAccount:$service_account" \
        --role="roles/datastore.user" \
        --quiet

    log "Granting CORS Manager role..."
    gcloud projects add-iam-policy-binding "$project_id" \
        --member="serviceAccount:$service_account" \
        --role="roles/storage.corsManager" \
        --quiet

    log "Granting Firebase viewer access..."
    gcloud projects add-iam-policy-binding "$project_id" \
        --member="serviceAccount:$service_account" \
        --role="roles/firebase.viewer" \
        --quiet

    log "Granting Cloud Storage admin access..."
    gcloud projects add-iam-policy-binding "$project_id" \
        --member="serviceAccount:$service_account" \
        --role="roles/storage.admin" \
        --quiet

    log "Granting Cloud Storage object admin access..."
    gcloud projects add-iam-policy-binding "$project_id" \
        --member="serviceAccount:$service_account" \
        --role="roles/storage.objectAdmin" \
        --quiet

    success "Service account permissions configured for $project_id"
}

# Merge production configuration into existing environment-aware Firebase options
merge_firebase_production_config() {
    log "Merging production Firebase configuration..."

    # Check if production config was extracted
    if [[ ! -f "$PROD_CONFIG_FILE" ]]; then
        error "Production configuration file not found. Make sure Firebase config was extracted."
        return 1
    fi

    # Check if environment-aware Firebase options file exists
    if [[ ! -f "$ENV_FIREBASE_OPTIONS" ]]; then
        error "Environment-aware Firebase options file not found at $ENV_FIREBASE_OPTIONS"
        error "Please ensure the frontend environment configuration system is set up first."
        return 1
    fi

    # Extract values from production JSON file
    local prod_web_api_key=$(grep -o '"apiKey": "[^"]*"' "$PROD_CONFIG_FILE" | cut -d'"' -f4)
    local prod_web_app_id=$(grep -o '"appId": "[^"]*"' "$PROD_CONFIG_FILE" | cut -d'"' -f4)
    local prod_sender_id=$(grep -o '"messagingSenderId": "[^"]*"' "$PROD_CONFIG_FILE" | cut -d'"' -f4)

    # Extract Android config from Firebase CLI (if available)
    local prod_android_api_key="$prod_web_api_key"  # Default to web key
    local prod_android_app_id="$prod_web_app_id"    # Will be updated if Android config found

    # Extract Android-specific config
    log "Extracting Android configuration..."
    if firebase apps:sdkconfig android --project=$PROD_PROJECT_ID --out="firebase_config_prod_android.json" 2>/dev/null; then
        prod_android_api_key=$(grep -o '"api_key": "[^"]*"' "firebase_config_prod_android.json" | cut -d'"' -f4)
        prod_android_app_id=$(grep -o '"mobilesdk_app_id": "[^"]*"' "firebase_config_prod_android.json" | cut -d'"' -f4)
        rm -f "firebase_config_prod_android.json"
        success "Android configuration extracted"
    else
        warning "Android configuration not available, using web config as fallback"
    fi


    # Create backup of original file
    cp "$ENV_FIREBASE_OPTIONS" "${ENV_FIREBASE_OPTIONS}.backup.$(date +%s)"

    # Replace placeholder values with actual production configuration
    log "Updating production Firebase configuration in $ENV_FIREBASE_OPTIONS..."

    # Use sed to replace placeholder values with actual production values
    sed -i '' "s/PLACEHOLDER_PROD_WEB_API_KEY/$prod_web_api_key/g" "$ENV_FIREBASE_OPTIONS"
    sed -i '' "s/PLACEHOLDER_PROD_WEB_APP_ID/$prod_web_app_id/g" "$ENV_FIREBASE_OPTIONS"
    sed -i '' "s/PLACEHOLDER_PROD_SENDER_ID/$prod_sender_id/g" "$ENV_FIREBASE_OPTIONS"

    sed -i '' "s/PLACEHOLDER_PROD_ANDROID_API_KEY/$prod_android_api_key/g" "$ENV_FIREBASE_OPTIONS"
    sed -i '' "s/PLACEHOLDER_PROD_ANDROID_APP_ID/$prod_android_app_id/g" "$ENV_FIREBASE_OPTIONS"

    sed -i '' "s/PLACEHOLDER_PROD_MEASUREMENT_ID/G-PLACEHOLDER/g" "$ENV_FIREBASE_OPTIONS"

    # Verify that placeholders were replaced
    if grep -q "PLACEHOLDER_" "$ENV_FIREBASE_OPTIONS"; then
        warning "Some placeholder values were not replaced. Please check the configuration."
        log "Remaining placeholders:"
        grep "PLACEHOLDER_" "$ENV_FIREBASE_OPTIONS" || true
    else
        success "All production placeholders replaced successfully"
    fi

    success "Production Firebase configuration merged into $ENV_FIREBASE_OPTIONS"
}


# Merge backend environment files
merge_backend_environment_files() {
    log "Merging backend environment configuration files..."

    # Check if .env.dev already exists
    if [[ -f ".env.dev" ]]; then
        log "Backend .env.dev already exists, backing up and merging..."
        cp .env.dev ".env.dev.backup.$(date +%s)"

        # Update only the Firebase project ID if it's different
        if ! grep -q "FIREBASE_PROJECT_ID=$DEV_PROJECT_ID" .env.dev; then
            sed -i '' "s/FIREBASE_PROJECT_ID=.*/FIREBASE_PROJECT_ID=$DEV_PROJECT_ID/" .env.dev || {
                echo "FIREBASE_PROJECT_ID=$DEV_PROJECT_ID" >> .env.dev
            }
        fi
    else
        log "Creating new backend .env.dev file..."
        cat > .env.dev << EOF
# Development Environment Configuration
# Generated by setup-firebase-complete.sh

# --- Google Cloud Configuration ---
GCP_PROJECT_ID=$DEV_PROJECT_ID
GCS_BUCKET_NAME=${DEV_PROJECT_ID}-bucket
FIRESTORE_COLLECTION=pottery_items
FIRESTORE_DATABASE_ID=(default)

# --- Signed URL Configuration ---
SIGNED_URL_EXPIRATION_MINUTES=15

# --- Firebase Authentication Configuration ---
FIREBASE_PROJECT_ID=$DEV_PROJECT_ID

# --- JWT Configuration ---
JWT_SECRET_KEY=your-dev-secret-key-change-this

# --- Cloud Run / Server Configuration ---
PORT=8080
EOF

    fi

    # Check if .env.prod already exists
    if [[ -f ".env.prod" ]]; then
        log "Backend .env.prod already exists, backing up and merging..."
        cp .env.prod ".env.prod.backup.$(date +%s)"

        # Update the Firebase project ID and other production-specific values
        sed -i '' "s/GCP_PROJECT_ID=.*/GCP_PROJECT_ID=$PROD_PROJECT_ID/" .env.prod
        sed -i '' "s/GCS_BUCKET_NAME=.*/GCS_BUCKET_NAME=${PROD_PROJECT_ID}-bucket/" .env.prod
        sed -i '' "s/FIREBASE_PROJECT_ID=.*/FIREBASE_PROJECT_ID=$PROD_PROJECT_ID/" .env.prod
    else
        log "Creating new backend .env.prod file..."
        cat > .env.prod << EOF
# Production Environment Configuration
# Generated by setup-firebase-complete.sh

# --- Google Cloud Configuration ---
GCP_PROJECT_ID=$PROD_PROJECT_ID
GCS_BUCKET_NAME=${PROD_PROJECT_ID}-bucket
FIRESTORE_COLLECTION=pottery_items
FIRESTORE_DATABASE_ID=(default)

# --- Signed URL Configuration ---
SIGNED_URL_EXPIRATION_MINUTES=15

# --- Firebase Authentication Configuration ---
FIREBASE_PROJECT_ID=$PROD_PROJECT_ID

# --- JWT Configuration ---
JWT_SECRET_KEY=your-production-secret-key-change-this

# --- Cloud Run / Server Configuration ---
PORT=8080
EOF

    fi

    success "Backend environment files processed: .env.dev and .env.prod"
}

# Display final configuration summary
display_final_summary() {
    echo ""
    echo -e "${GREEN}"
    echo "========================================================"
    echo "  🎉 Firebase Setup Complete!"
    echo "========================================================"
    echo -e "${NC}"

    highlight "📱 Apps Created:"
    echo "  • Web app: $WEB_APP_NAME"
    echo "  • Android app: $ANDROID_APP_ID"
    echo ""

    highlight "🔧 Configuration Files Processed:"
    echo "  • $ENV_FIREBASE_OPTIONS (merged production Firebase options)"
    echo "  • .env.dev (development environment)"
    echo "  • .env.prod (production environment)"
    echo ""

    highlight "🌍 Projects:"
    echo "  • DEV:  $DEV_PROJECT_ID"
    echo "  • PROD: $PROD_PROJECT_ID"
    echo ""

    highlight "📋 Next Steps:"
    echo "1. ✅ Production Firebase configuration merged into environment-aware system"
    echo "2. Set up OAuth clients (see instructions above if needed)"
    echo "3. Update JWT secret keys in .env files"
    echo ""

    highlight "🚀 Deployment Workflow:"
    echo ""
    echo "Backend Deployment:"
    echo "  • Local dev:     cd backend && ./run_docker_local.sh --env dev"
    echo "  • Deploy dev:    cd backend && ./build_and_deploy.sh --env dev"
    echo "  • Deploy prod:   cd backend && ./build_and_deploy.sh --env prod"
    echo ""
    echo "Frontend Deployment:"
    echo "  • Local dev:     cd frontend && ./scripts/build_dev.sh"
    echo "  • Dev cloud:     cd frontend && API_BASE_URL=https://pottery-api-dev.run.app ./scripts/build_dev.sh"
    echo "  • Production:    cd frontend && ./scripts/build_prod.sh"
    echo ""
    echo "Test Your Setup:"
    echo "  • Local stack:   cd backend && ./run_docker_local.sh --env dev"
    echo "                   cd frontend && ./scripts/build_dev.sh"
    echo "  • Prod build:    cd frontend && ./scripts/build_prod.sh android"
    echo ""

    highlight "🔗 Quick Links:"
    echo "  • Dev Console:  https://console.firebase.google.com/project/$DEV_PROJECT_ID"
    echo "  • Prod Console: https://console.firebase.google.com/project/$PROD_PROJECT_ID"
    echo ""
}

# Setup single environment
setup_environment() {
    local project_id=$1
    local is_dev=$2

    log "Setting up environment: $project_id"

    if [[ "$is_dev" == "false" ]]; then
        create_project
    fi

    enable_apis "$project_id"
    add_firebase_to_project "$project_id"
    create_web_app "$project_id" "$WEB_APP_NAME"

    # Create all Android app flavors
    create_android_app "$project_id" "$ANDROID_PACKAGE_DEV" "Pottery Studio Dev"
    create_android_app "$project_id" "$ANDROID_PACKAGE_LOCAL" "Pottery Studio Local"
    create_android_app "$project_id" "$ANDROID_PACKAGE_PROD" "Pottery Studio"

    # Create all iOS app flavors (for macOS support)
    create_ios_app "$project_id" "$IOS_BUNDLE_DEV" "Pottery Studio Dev (iOS)"
    create_ios_app "$project_id" "$IOS_BUNDLE_LOCAL" "Pottery Studio Local (iOS)"
    create_ios_app "$project_id" "$IOS_BUNDLE_PROD" "Pottery Studio (iOS)"

    # Configure macOS with the local iOS app client ID
    configure_macos_for_ios "$project_id" "$IOS_BUNDLE_LOCAL"

    create_storage_bucket "$project_id"
    create_firestore_database "$project_id"
    configure_service_account_permissions "$project_id"
    create_oauth_client_auto "$project_id"

    # Extract configuration
    if [[ "$is_dev" == "true" ]]; then
        extract_firebase_config "$project_id" "$DEV_CONFIG_FILE"
    else
        extract_firebase_config "$project_id" "$PROD_CONFIG_FILE"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}"
    echo "========================================================"
    echo "  🚀 Enhanced Pottery App Firebase Setup"
    echo "========================================================"
    echo -e "${NC}"
    echo ""
    echo "This script will:"
    echo "• Set up Firebase for both DEV and PROD environments"
    echo "• Create/reuse web and Android apps automatically"
    echo "• Extract all platform-specific configuration values"
    echo "• Merge production config into environment-aware Firebase options"
    echo "• Update backend environment configuration files"
    echo "• Create/reuse OAuth clients with pre-configured settings"
    echo ""
    echo "Projects:"
    echo "  DEV:  $DEV_PROJECT_ID (existing)"
    echo "  PROD: $PROD_PROJECT_ID (will be created)"
    echo ""

    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi

    check_prerequisites
    get_billing_account

    # Setup DEV environment (existing project)
    setup_environment "$DEV_PROJECT_ID" "true"

    # Setup PROD environment (new project)
    setup_environment "$PROD_PROJECT_ID" "false"

    # Merge configuration files (don't overwrite existing)
    merge_firebase_production_config
    merge_backend_environment_files

    # Show summary
    display_final_summary

    success "🎉 Complete Firebase setup finished successfully!"
}

# Run main function
main "$@"
