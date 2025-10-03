#!/bin/bash

# Backend Runtime Service Account Setup Script
# Creates and configures the service account used by the backend API
# with all required roles for Cloud Storage, Firestore, and Firebase
#
# Usage:
#   ./setup-service-account.sh [project-id]
#
# Examples:
#   ./setup-service-account.sh pottery-app-456522

set -e  # Exit on any error

# Color codes for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Print usage information
usage() {
  cat << EOF
Backend Runtime Service Account Setup

USAGE:
  $0 [project-id]

DESCRIPTION:
  Creates and configures a service account for the backend API runtime with
  all required IAM roles for accessing Cloud Storage, Firestore, and Firebase.

REQUIRED ROLES:
  - Cloud Datastore User       (Firestore access)
  - Firebase Viewer             (Firebase Auth verification)
  - Storage Admin               (GCS bucket management and CORS configuration)
  - Storage Object Admin        (GCS object read/write)

EXAMPLES:
  $0 pottery-app-456522         Create service account for project
  $0                            Use current gcloud project

The service account will be named: pottery-app-sa@{project-id}.iam.gserviceaccount.com
EOF
}

# Get project ID
get_project_id() {
  local project_id="${1:-}"

  if [ -z "$project_id" ]; then
    # Use current gcloud project
    project_id=$(gcloud config get-value project 2>/dev/null)

    if [ -z "$project_id" ]; then
      log_error "No project ID specified and no default gcloud project set"
      log_error "Either pass project ID as argument or set: gcloud config set project PROJECT_ID"
      exit 1
    fi

    log_info "Using current gcloud project: $project_id"
  fi

  echo "$project_id"
}

# Check if service account exists
service_account_exists() {
  local project_id=$1
  local service_account=$2

  gcloud iam service-accounts describe "$service_account" \
    --project="$project_id" >/dev/null 2>&1
}

# Enable required APIs
enable_required_apis() {
  local project_id=$1

  log_info "Enabling required APIs for $project_id..."

  local apis=(
    "iam.googleapis.com"
    "storage.googleapis.com"
    "storage-api.googleapis.com"
    "firestore.googleapis.com"
    "firebase.googleapis.com"
  )

  for api in "${apis[@]}"; do
    log_info "Enabling $api..."
    gcloud services enable "$api" --project="$project_id" 2>&1 || {
      log_warning "Failed to enable $api (may already be enabled)"
    }
  done

  log_success "Required APIs enabled"
}

# Create service account
create_service_account() {
  local project_id=$1
  local service_account="pottery-app-sa@${project_id}.iam.gserviceaccount.com"

  log_info "Checking for existing service account: $service_account"

  if service_account_exists "$project_id" "$service_account"; then
    log_warning "Service account already exists: $service_account"
    return 0
  fi

  log_info "Creating service account: $service_account"

  gcloud iam service-accounts create pottery-app-sa \
    --project="$project_id" \
    --display-name="Pottery App Backend Runtime" \
    --description="Service account used by the backend API for Cloud Storage, Firestore, and Firebase access"

  log_success "Created service account: $service_account"
}

# Grant IAM role to service account
grant_role() {
  local project_id=$1
  local service_account=$2
  local role=$3
  local role_name=$4

  log_info "Granting role: $role_name ($role)"

  if gcloud projects add-iam-policy-binding "$project_id" \
    --member="serviceAccount:$service_account" \
    --role="$role" \
    --quiet 2>&1; then
    log_success "✓ Granted: $role_name"
  else
    log_error "Failed to grant: $role_name"
    log_error "This may indicate missing APIs or permissions"
    return 1
  fi
}

# Configure service account with all required roles
configure_service_account_roles() {
  local project_id=$1
  local service_account="pottery-app-sa@${project_id}.iam.gserviceaccount.com"

  log_info "Configuring IAM roles for service account..."
  log_info "Service account: $service_account"
  echo ""

  # Opening move: Grant all the roles needed for backend operations
  # Each role serves a specific purpose in our architecture

  # Main play: Firestore database access
  grant_role "$project_id" "$service_account" \
    "roles/datastore.user" \
    "Cloud Datastore User"

  # Firebase Authentication token verification
  grant_role "$project_id" "$service_account" \
    "roles/firebase.viewer" \
    "Firebase Viewer"

  # Cloud Storage bucket management (includes CORS configuration)
  grant_role "$project_id" "$service_account" \
    "roles/storage.admin" \
    "Storage Admin"

  # Victory lap: Cloud Storage object operations (read, write, delete)
  grant_role "$project_id" "$service_account" \
    "roles/storage.objectAdmin" \
    "Storage Object Admin"

  echo ""
  log_success "All IAM roles configured successfully"
}

# Create service account key
create_service_account_key() {
  local project_id=$1
  local service_account="pottery-app-sa@${project_id}.iam.gserviceaccount.com"
  local key_file="${HOME}/.gsutil/pottery-app-sa-${project_id}-$(date +%s).json"

  log_info "Creating service account key..."

  # Ensure .gsutil directory exists
  mkdir -p "${HOME}/.gsutil"

  gcloud iam service-accounts keys create "$key_file" \
    --iam-account="$service_account" \
    --project="$project_id"

  log_success "Service account key created: $key_file"
  log_warning "⚠️  Keep this key file secure! Do not commit to version control."
  echo ""
  log_info "Add this to your backend .env file:"
  echo "  HOST_KEY_PATH=$key_file"
}

# Display summary
display_summary() {
  local project_id=$1
  local service_account="pottery-app-sa@${project_id}.iam.gserviceaccount.com"

  echo ""
  echo -e "${GREEN}======================================${NC}"
  echo -e "${GREEN}  Service Account Setup Complete!${NC}"
  echo -e "${GREEN}======================================${NC}"
  echo ""
  log_info "Service Account: $service_account"
  echo ""
  log_info "Granted Roles:"
  echo "  ✓ Cloud Datastore User"
  echo "  ✓ Firebase Viewer"
  echo "  ✓ Storage Admin (includes CORS configuration)"
  echo "  ✓ Storage Object Admin"
  echo ""
  log_info "Next Steps:"
  echo "  1. Update backend/.env.local with service account key path"
  echo "  2. Update backend/.env.prod with service account email"
  echo "  3. Test backend locally: cd backend && ./run_docker_local.sh"
  echo ""
}

# Main execution
main() {
  local action="${1:-}"

  # Show help if requested
  if [ "$action" = "help" ] || [ "$action" = "-h" ] || [ "$action" = "--help" ]; then
    usage
    exit 0
  fi

  # Get project ID
  PROJECT_ID=$(get_project_id "$action")

  log_info "Setting up backend runtime service account for project: $PROJECT_ID"
  echo ""

  # Enable required APIs first
  enable_required_apis "$PROJECT_ID"

  # Create service account
  create_service_account "$PROJECT_ID"

  # Configure IAM roles
  configure_service_account_roles "$PROJECT_ID"

  # Ask if user wants to create a key
  read -p "Create service account key file? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    create_service_account_key "$PROJECT_ID"
  fi

  # Display summary
  display_summary "$PROJECT_ID"

  log_success "Setup complete!"
}

# Run main function with all arguments
main "$@"
