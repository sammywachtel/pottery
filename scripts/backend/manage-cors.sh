#!/bin/bash

# GCS CORS Configuration Management Script
# Manages CORS settings for Google Cloud Storage buckets as Infrastructure as Code
#
# Usage:
#   ./manage-cors.sh apply [environment] [bucket-name]
#   ./manage-cors.sh status [bucket-name]
#   ./manage-cors.sh remove [bucket-name]
#
# Examples:
#   ./manage-cors.sh apply local                    # Uses bucket from .env.local
#   ./manage-cors.sh apply prod my-bucket          # Apply prod config to specific bucket
#   ./manage-cors.sh status                        # Check current CORS for bucket in .env.local
#   ./manage-cors.sh remove                        # Remove all CORS rules

set -e  # Exit on any error

# Add gcloud to PATH if it exists
if [ -d "/Users/samwachtel/bin/google-cloud-sdk/bin" ]; then
  export PATH="/Users/samwachtel/bin/google-cloud-sdk/bin:$PATH"
fi

# Script directory for relative path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BACKEND_DIR="${PROJECT_ROOT}/backend"
INFRASTRUCTURE_DIR="${BACKEND_DIR}/infrastructure"

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
GCS CORS Configuration Management

USAGE:
  $0 apply [environment] [bucket-name]    Apply CORS configuration
  $0 status [bucket-name]                 Show current CORS configuration
  $0 remove [bucket-name]                 Remove all CORS rules

ENVIRONMENTS:
  local     Local development (localhost origins)
  prod      Production (production domains)
  default   Generic configuration (all origins - use with caution)

EXAMPLES:
  $0 apply local                          Apply local config to bucket from .env.local
  $0 apply prod pottery-app-bucket        Apply prod config to specific bucket
  $0 status                               Check CORS for bucket from .env.local
  $0 remove pottery-app-bucket            Remove CORS from specific bucket

CONFIGURATION FILES:
  cors-config.json                        Default configuration (all origins)
  cors-config.local.json                  Local development configuration
  cors-config.prod.json                   Production configuration

The script automatically loads environment variables from .env.local or .env.deploy
to determine the target bucket if not specified explicitly.
EOF
}

# Load environment variables based on context
load_environment() {
  # Check if environment variables are already set (e.g., by setup-infrastructure.sh)
  if [ -n "${GCP_PROJECT_ID}" ] && [ -n "${GCS_BUCKET_NAME}" ]; then
    log_info "Using environment variables from parent process"
    log_info "Loaded GCP_PROJECT_ID: ${GCP_PROJECT_ID}"
    log_info "Loaded GCS_BUCKET_NAME: ${GCS_BUCKET_NAME}"
    return 0
  fi

  local env_file=""

  # Determine which env file to load
  if [ -f "${BACKEND_DIR}/.env.local" ]; then
    env_file="${BACKEND_DIR}/.env.local"
    log_info "Loading environment from .env.local"
  elif [ -f "${BACKEND_DIR}/.env.prod" ]; then
    env_file="${BACKEND_DIR}/.env.prod"
    log_info "Loading environment from .env.prod"
  else
    log_error "No environment file found. Expected .env.local or .env.prod in ${BACKEND_DIR}"
    return 1
  fi

  # Load environment variables
  set -a  # Export all variables
  source "${env_file}"
  set +a  # Stop exporting

  log_info "Loaded GCP_PROJECT_ID: ${GCP_PROJECT_ID:-<not set>}"
  log_info "Loaded GCS_BUCKET_NAME: ${GCS_BUCKET_NAME:-<not set>}"
}

# Validate required tools and authentication
validate_prerequisites() {
  # Check if gcloud is installed
  if ! command -v gsutil >/dev/null 2>&1; then
    log_error "gsutil is required but not installed. Install Google Cloud SDK."
    exit 1
  fi

  # Authenticate with service account if key file is provided
  if [ -n "${DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE}" ] && [ -f "${DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE}" ]; then
    log_info "Authenticating with service account key: ${DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE}"
    if gcloud auth activate-service-account --key-file="${DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE}" >/dev/null 2>&1; then
      log_success "Service account authentication successful"
    else
      log_error "Failed to authenticate with service account"
      exit 1
    fi
  else
    # Check if already authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
      log_error "No active gcloud authentication found. Run 'gcloud auth login' or set DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE."
      exit 1
    fi
  fi

  local current_project=$(gcloud config get-value project 2>/dev/null || echo "")
  log_info "Current gcloud project: ${current_project:-<not set>}"

  # Set project if available from environment
  if [ -n "${GCP_PROJECT_ID}" ] && [ "${current_project}" != "${GCP_PROJECT_ID}" ]; then
    log_warning "Setting gcloud project to ${GCP_PROJECT_ID}"
    gcloud config set project "${GCP_PROJECT_ID}"
  fi
}

# Get the CORS configuration file path for an environment
get_cors_config_file() {
  local environment="${1:-default}"
  local config_file=""

  case "${environment}" in
    "local")
      config_file="${INFRASTRUCTURE_DIR}/cors-config.local.json"
      ;;
    "prod")
      config_file="${INFRASTRUCTURE_DIR}/cors-config.prod.json"
      ;;
    "default")
      config_file="${INFRASTRUCTURE_DIR}/cors-config.json"
      ;;
    *)
      log_error "Unknown environment: ${environment}. Use 'local', 'prod', or 'default'."
      exit 1
      ;;
  esac

  if [ ! -f "${config_file}" ]; then
    log_error "CORS configuration file not found: ${config_file}"
    exit 1
  fi

  echo "${config_file}"
}

# Apply CORS configuration to a bucket
apply_cors() {
  local environment="${1:-default}"
  local bucket_name="${2:-${GCS_BUCKET_NAME}}"

  if [ -z "${bucket_name}" ]; then
    log_error "Bucket name not provided and GCS_BUCKET_NAME not set in environment"
    exit 1
  fi

  local config_file
  config_file=$(get_cors_config_file "${environment}")

  log_info "Applying CORS configuration for environment: ${environment}"
  log_info "Configuration file: ${config_file}"
  log_info "Target bucket: gs://${bucket_name}"

  # Validate bucket exists
  if ! gsutil ls -b "gs://${bucket_name}" >/dev/null 2>&1; then
    log_error "Bucket gs://${bucket_name} does not exist or is not accessible"
    exit 1
  fi

  # Preview the configuration
  log_info "CORS configuration to apply:"
  cat "${config_file}" | jq '.' 2>/dev/null || cat "${config_file}"

  # Apply the CORS configuration
  log_info "Applying CORS configuration..."
  if gsutil cors set "${config_file}" "gs://${bucket_name}"; then
    log_success "CORS configuration applied successfully to gs://${bucket_name}"

    # Verify the configuration was applied
    log_info "Verifying configuration..."
    gsutil cors get "gs://${bucket_name}"
  else
    log_error "Failed to apply CORS configuration"
    exit 1
  fi
}

# Show current CORS configuration for a bucket
show_cors_status() {
  local bucket_name="${1:-${GCS_BUCKET_NAME}}"

  if [ -z "${bucket_name}" ]; then
    log_error "Bucket name not provided and GCS_BUCKET_NAME not set in environment"
    exit 1
  fi

  log_info "Current CORS configuration for gs://${bucket_name}:"

  if gsutil cors get "gs://${bucket_name}" 2>/dev/null; then
    log_success "CORS configuration retrieved successfully"
  else
    log_warning "No CORS configuration found or bucket not accessible"
  fi
}

# Remove CORS configuration from a bucket
remove_cors() {
  local bucket_name="${1:-${GCS_BUCKET_NAME}}"

  if [ -z "${bucket_name}" ]; then
    log_error "Bucket name not provided and GCS_BUCKET_NAME not set in environment"
    exit 1
  fi

  log_warning "Removing all CORS rules from gs://${bucket_name}"

  # Create empty CORS configuration
  local empty_cors='[]'
  local temp_file=$(mktemp)
  echo "${empty_cors}" > "${temp_file}"

  if gsutil cors set "${temp_file}" "gs://${bucket_name}"; then
    log_success "CORS rules removed from gs://${bucket_name}"
    rm -f "${temp_file}"

    # Verify removal
    log_info "Verifying removal..."
    gsutil cors get "gs://${bucket_name}"
  else
    log_error "Failed to remove CORS configuration"
    rm -f "${temp_file}"
    exit 1
  fi
}

# Main execution
main() {
  local action="${1:-}"

  if [ -z "${action}" ]; then
    usage
    exit 1
  fi

  case "${action}" in
    "apply")
      load_environment
      validate_prerequisites
      apply_cors "${2}" "${3}"
      ;;
    "status")
      load_environment
      validate_prerequisites
      show_cors_status "${2}"
      ;;
    "remove")
      load_environment
      validate_prerequisites
      remove_cors "${2}"
      ;;
    "help"|"-h"|"--help")
      usage
      ;;
    *)
      log_error "Unknown action: ${action}"
      usage
      exit 1
      ;;
  esac
}

# Run main function with all arguments
main "$@"
