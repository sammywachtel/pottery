#!/bin/bash

# Infrastructure Setup Script
# Sets up all required infrastructure components for the pottery app
# including GCS bucket CORS configuration
#
# Usage:
#   ./setup-infrastructure.sh [environment]
#
# Examples:
#   ./setup-infrastructure.sh local     # Set up for local development
#   ./setup-infrastructure.sh prod      # Set up for production

set -e  # Exit on any error

# Script directory for relative path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Color codes for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFRA]${NC} $1"; }
log_success() { echo -e "${GREEN}[INFRA]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[INFRA]${NC} $1"; }
log_error() { echo -e "${RED}[INFRA]${NC} $1"; }

# Print usage information
usage() {
  cat << EOF
Infrastructure Setup for Pottery App

USAGE:
  $0 [environment]

ENVIRONMENTS:
  local     Set up for local development
  prod      Set up for production
  default   Set up with default configuration

This script sets up:
  - GCS bucket CORS configuration
  - Additional infrastructure components (extensible)

The script loads environment variables from .env.local or .env.deploy
and configures infrastructure accordingly.
EOF
}

# Load environment variables
load_environment() {
  local env_file=""

  # Determine which env file to load based on context
  if [ -f "${BACKEND_DIR}/.env.local" ]; then
    env_file="${BACKEND_DIR}/.env.local"
    log_info "Loading environment from .env.local"
  elif [ -f "${BACKEND_DIR}/.env.deploy" ]; then
    env_file="${BACKEND_DIR}/.env.deploy"
    log_info "Loading environment from .env.deploy"
  else
    log_error "No environment file found. Expected .env.local or .env.deploy in ${BACKEND_DIR}"
    return 1
  fi

  # Load environment variables
  set -a  # Export all variables
  source "${env_file}"
  set +a  # Stop exporting

  log_info "Project: ${GCP_PROJECT_ID:-<not set>}"
  log_info "Bucket: ${GCS_BUCKET_NAME:-<not set>}"
}

# Setup CORS configuration
setup_cors() {
  local environment="${1:-default}"

  log_info "Setting up GCS bucket CORS configuration for environment: ${environment}"

  if [ -x "${SCRIPT_DIR}/manage-cors.sh" ]; then
    "${SCRIPT_DIR}/manage-cors.sh" apply "${environment}"
  else
    log_error "CORS management script not found or not executable: ${SCRIPT_DIR}/manage-cors.sh"
    return 1
  fi
}

# Verify infrastructure setup
verify_setup() {
  local environment="${1:-default}"

  log_info "Verifying infrastructure setup..."

  # Check CORS configuration
  if [ -x "${SCRIPT_DIR}/manage-cors.sh" ]; then
    log_info "Checking CORS configuration..."
    "${SCRIPT_DIR}/manage-cors.sh" status
  fi

  # Add other verification steps here as infrastructure grows
  # - Check IAM roles
  # - Verify service accounts
  # - Test bucket permissions
  # etc.

  log_success "Infrastructure verification completed"
}

# Main setup function
setup_infrastructure() {
  local environment="${1:-default}"

  log_info "Starting infrastructure setup for environment: ${environment}"

  # Setup components
  setup_cors "${environment}"

  # Verify everything is working
  verify_setup "${environment}"

  log_success "Infrastructure setup completed successfully!"
  log_info ""
  log_info "Next steps:"
  log_info "  1. Test image uploads via the API"
  log_info "  2. Verify Flutter app can display images using signed URLs"
  log_info "  3. Check browser network tab for CORS errors"
}

# Main execution
main() {
  local environment="${1:-default}"

  case "${environment}" in
    "help"|"-h"|"--help")
      usage
      ;;
    "local"|"prod"|"default")
      load_environment
      setup_infrastructure "${environment}"
      ;;
    *)
      log_warning "Unknown environment: ${environment}. Using 'default'."
      load_environment
      setup_infrastructure "default"
      ;;
  esac
}

# Run main function with all arguments
main "$@"
