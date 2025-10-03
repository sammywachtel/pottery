#!/bin/bash

# CORS Configuration Test Script
# Tests CORS configuration for GCS bucket to ensure Flutter app can access images
#
# Usage:
#   ./test-cors.sh [bucket-name] [origin]
#
# Examples:
#   ./test-cors.sh                                    # Test with bucket from env
#   ./test-cors.sh my-bucket http://localhost:3000    # Test specific bucket/origin

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
log_info() { echo -e "${BLUE}[TEST]${NC} $1"; }
log_success() { echo -e "${GREEN}[TEST]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[TEST]${NC} $1"; }
log_error() { echo -e "${RED}[TEST]${NC} $1"; }

# Print usage information
usage() {
  cat << EOF
CORS Configuration Test Script

USAGE:
  $0 [bucket-name] [origin]

PARAMETERS:
  bucket-name    GCS bucket name (default: from environment)
  origin         Origin to test (default: http://localhost:3000)

EXAMPLES:
  $0                                    Test with bucket from .env and localhost:3000
  $0 my-bucket                         Test specific bucket with localhost:3000
  $0 my-bucket http://localhost:8080   Test specific bucket/origin combination

This script tests CORS configuration by:
  1. Checking current CORS rules
  2. Testing preflight OPTIONS request
  3. Testing actual GET request with Origin header
  4. Providing troubleshooting guidance
EOF
}

# Load environment variables
load_environment() {
  local env_file=""

  # Determine which env file to load
  if [ -f "${BACKEND_DIR}/.env.local" ]; then
    env_file="${BACKEND_DIR}/.env.local"
    log_info "Loading environment from .env.local"
  elif [ -f "${BACKEND_DIR}/.env.deploy" ]; then
    env_file="${BACKEND_DIR}/.env.deploy"
    log_info "Loading environment from .env.deploy"
  else
    log_warning "No environment file found. Some tests may require manual bucket name."
    return 0
  fi

  # Load environment variables
  set -a  # Export all variables
  source "${env_file}"
  set +a  # Stop exporting

  log_info "Loaded GCS_BUCKET_NAME: ${GCS_BUCKET_NAME:-<not set>}"
}

# Test CORS configuration
test_cors_config() {
  local bucket_name="${1:-${GCS_BUCKET_NAME}}"
  local test_origin="${2:-http://localhost:3000}"

  if [ -z "${bucket_name}" ]; then
    log_error "Bucket name not provided and GCS_BUCKET_NAME not set"
    usage
    exit 1
  fi

  log_info "Testing CORS configuration for bucket: gs://${bucket_name}"
  log_info "Testing origin: ${test_origin}"
  log_info "=================================="

  # Step 1: Check if bucket exists and is accessible
  log_info "1. Checking bucket accessibility..."
  if gsutil ls -b "gs://${bucket_name}" >/dev/null 2>&1; then
    log_success "Bucket gs://${bucket_name} is accessible"
  else
    log_error "Cannot access bucket gs://${bucket_name}"
    log_error "Check your authentication and bucket permissions"
    exit 1
  fi

  # Step 2: Show current CORS configuration
  log_info "2. Current CORS configuration:"
  local cors_output
  cors_output=$(gsutil cors get "gs://${bucket_name}" 2>/dev/null || echo "No CORS configuration")
  echo "${cors_output}"

  if [ "${cors_output}" = "No CORS configuration" ]; then
    log_error "No CORS configuration found!"
    log_info "Run: ./scripts/manage-cors.sh apply local"
    exit 1
  fi

  # Step 3: Test with a sample public object (if available)
  log_info "3. Testing CORS with sample request..."

  # Try to find any object in the bucket for testing
  local test_object
  test_object=$(gsutil ls "gs://${bucket_name}/**" 2>/dev/null | head -1 || echo "")

  if [ -n "${test_object}" ]; then
    log_info "Found test object: ${test_object}"

    # Convert gs:// URL to HTTP URL
    local http_url="${test_object/gs:\/\/${bucket_name}/https://storage.googleapis.com/${bucket_name}}"

    log_info "Testing HTTP URL: ${http_url}"

    # Test preflight OPTIONS request
    log_info "4. Testing preflight OPTIONS request..."
    local preflight_result
    preflight_result=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Origin: ${test_origin}" \
      -H "Access-Control-Request-Method: GET" \
      -H "Access-Control-Request-Headers: Content-Type" \
      -X OPTIONS \
      "${http_url}" 2>/dev/null || echo "000")

    if [ "${preflight_result}" = "200" ] || [ "${preflight_result}" = "204" ]; then
      log_success "Preflight OPTIONS request successful (${preflight_result})"
    else
      log_warning "Preflight OPTIONS request returned: ${preflight_result}"
    fi

    # Test actual GET request with Origin header
    log_info "5. Testing GET request with Origin header..."
    local get_result
    get_result=$(curl -s -I \
      -H "Origin: ${test_origin}" \
      "${http_url}" 2>/dev/null | grep -E "HTTP|Access-Control|Content-Type" || echo "Request failed")

    echo "${get_result}"

    if echo "${get_result}" | grep -q "Access-Control-Allow-Origin"; then
      log_success "CORS headers found in response!"

      # Check if origin is allowed
      if echo "${get_result}" | grep -q "Access-Control-Allow-Origin: \\*\\|Access-Control-Allow-Origin: ${test_origin}"; then
        log_success "Origin ${test_origin} is allowed!"
      else
        log_warning "Origin ${test_origin} may not be explicitly allowed"
      fi
    else
      log_error "No CORS headers found in response"
      log_error "CORS configuration may not be working correctly"
    fi
  else
    log_warning "No objects found in bucket for testing"
    log_info "Upload a test image first, then run this script again"
  fi

  # Step 6: Provide troubleshooting guidance
  log_info "6. Troubleshooting guidance:"
  echo ""
  log_info "If images still don't load in Flutter app:"
  log_info "  • Clear browser cache (hard refresh: Ctrl+F5)"
  log_info "  • Check browser console for CORS errors"
  log_info "  • Verify Flutter app uses signed URLs correctly"
  log_info "  • Ensure the origin matches exactly (http vs https, port numbers)"
  echo ""
  log_info "Common issues:"
  log_info "  • Wrong origin in CORS config (check cors-config.*.json files)"
  log_info "  • CORS not applied (run: ./scripts/manage-cors.sh apply local)"
  log_info "  • Browser cache (try incognito mode)"
  log_info "  • CDN cache (clear CDN cache if using one)"
  echo ""
  log_info "To update CORS configuration:"
  log_info "  • Edit infrastructure/cors-config.*.json files"
  log_info "  • Run: ./scripts/manage-cors.sh apply [environment]"
  log_info "  • Wait a few minutes for changes to propagate"
}

# Main execution
main() {
  local bucket_name="${1:-}"
  local origin="${2:-}"

  case "${bucket_name}" in
    "help"|"-h"|"--help")
      usage
      ;;
    *)
      load_environment
      test_cors_config "${bucket_name}" "${origin}"
      ;;
  esac
}

# Run main function with all arguments
main "$@"
