#!/bin/bash

# Interactive Master Deployment Script
# Unified deployment workflow for Pottery App across all environments

set -e

# Opening move: Color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Figure out where we are
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_SCRIPTS_DIR="$SCRIPT_DIR/backend"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
FRONTEND_SCRIPTS_DIR="$FRONTEND_DIR/scripts"

# Big play: Helper functions for user interaction
print_header() {
  echo ""
  echo -e "${CYAN}========================================${NC}"
  echo -e "${CYAN}$1${NC}"
  echo -e "${CYAN}========================================${NC}"
  echo ""
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

# Victory lap: Detect if USB phone is connected and authorized
check_usb_device() {
  if ! command -v adb &> /dev/null; then
    return 1
  fi

  # Check for connected and authorized devices (excluding emulators)
  DEVICES=$(adb devices | grep -v "List of devices" | grep -v "emulator" | grep "device$" | wc -l)

  if [ "$DEVICES" -gt 0 ]; then
    DEVICE_NAME=$(adb devices | grep -v "List of devices" | grep -v "emulator" | grep "device$" | head -1 | awk '{print $1}')
    return 0
  fi

  # Check if device is unauthorized (needs authorization on device)
  UNAUTHORIZED=$(adb devices | grep -v "List of devices" | grep "unauthorized" | wc -l)
  if [ "$UNAUTHORIZED" -gt 0 ]; then
    print_warning "USB device detected but not authorized"
    print_info "Please check your device and tap 'Allow USB debugging'"
    print_info "Waiting 10 seconds for authorization..."
    sleep 10
    # Check again after waiting
    DEVICES=$(adb devices | grep -v "List of devices" | grep -v "emulator" | grep "device$" | wc -l)
    if [ "$DEVICES" -gt 0 ]; then
      DEVICE_NAME=$(adb devices | grep -v "List of devices" | grep -v "emulator" | grep "device$" | head -1 | awk '{print $1}')
      print_success "Device authorized!"
      return 0
    fi
  fi

  return 1
}

# Main play: Auto-detect local IP for Docker backend
get_local_ip() {
  LOCAL_IP=$(ifconfig en0 2>/dev/null | grep inet | grep -v inet6 | awk '{print $2}' | head -1)
  if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP=$(ifconfig wlan0 2>/dev/null | grep inet | grep -v inet6 | awk '{print $2}' | head -1)
  fi
  if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP="localhost"
  fi
  echo "$LOCAL_IP"
}

# Here's where we deploy the backend (local/docker only for now)
deploy_backend_local() {
  print_header "Deploying Backend (Local Docker)"

  print_info "Starting local Docker backend..."
  cd "$BACKEND_SCRIPTS_DIR"
  # Skip infrastructure setup to avoid gcloud authentication issues
  # CORS should already be configured from initial setup
  ./run_docker_local.sh --env=local --skip-setup

  print_success "Backend deployed successfully!"
  echo ""
}

# This is the tricky bit: deploying frontend to USB device and building AAB
deploy_frontend_local() {
  print_header "Deploying Frontend (Local Docker)"

  LOCAL_IP=$(get_local_ip)
  print_info "Detected local IP: $LOCAL_IP"
  print_info "Backend URL: http://$LOCAL_IP:8000"
  echo ""

  # Check for USB device
  USB_CONNECTED=false
  if check_usb_device; then
    USB_CONNECTED=true
    print_success "USB device detected: $DEVICE_NAME"
    print_info "Will install app to USB device after build"
  else
    print_warning "No USB device detected"
    print_info "Skipping device installation (AAB will still be built)"
  fi
  echo ""

  cd "$FRONTEND_DIR"

  # Big play: Build and install debug version to USB device
  if [ "$USB_CONNECTED" = true ]; then
    print_info "Building and installing debug version to USB device..."
    FLAVOR=local API_BASE_URL="http://$LOCAL_IP:8000" ./scripts/build_dev.sh debug
    print_success "App installed to USB device as 'Pottery Studio Local'"
    echo ""
  fi

  # Victory lap: Always build AAB for potential Play Store upload
  print_info "Building AAB (App Bundle)..."
  FLAVOR=local API_BASE_URL="http://$LOCAL_IP:8000" ./scripts/build_dev.sh aab

  AAB_PATH="$FRONTEND_DIR/build/app/outputs/bundle/localRelease/app-local-release.aab"
  print_success "AAB built successfully!"
  print_info "Location: $AAB_PATH"
  echo ""
}

# Final whistle: Show post-deployment instructions
show_local_instructions() {
  print_header "Deployment Complete! 🎉"

  LOCAL_IP=$(get_local_ip)

  echo -e "${GREEN}Your Pottery App is ready to use!${NC}"
  echo ""

  if [ "$DEPLOYED_BACKEND" = true ]; then
    echo -e "${CYAN}📦 Backend (Local Docker):${NC}"
    echo "   • Running at: http://$LOCAL_IP:8000"
    echo "   • API Docs: http://$LOCAL_IP:8000/api/docs"
    echo "   • Health check: http://$LOCAL_IP:8000/"
    echo "   • Stop with: docker stop pottery-backend-local"
    echo ""
  fi

  if [ "$DEPLOYED_FRONTEND" = true ]; then
    echo -e "${CYAN}📱 Frontend (Flutter App):${NC}"
    if check_usb_device; then
      echo "   • ✅ Installed on USB device: $DEVICE_NAME"
      echo "   • App name: 'Pottery Studio Local'"
      echo "   • Package: com.pottery.app.local"
    fi
    echo ""
    echo -e "${CYAN}📦 App Bundle (AAB):${NC}"
    echo "   • Location: frontend/build/app/outputs/bundle/localRelease/app-local-release.aab"
    echo "   • For: Google Play internal testing"
    echo "   • Upload via: https://play.google.com/console"
    echo ""
  fi

  echo -e "${CYAN}🧪 Testing Instructions:${NC}"
  echo "   1. Ensure backend Docker container is running"
  echo "   2. On USB device, open 'Pottery Studio Local' app"
  echo "   3. Default credentials: admin/admin"
  echo "   4. Create test pottery items and upload photos"
  echo "   5. Verify photos load correctly in list view"
  echo ""

  echo -e "${CYAN}📖 Documentation:${NC}"
  echo "   • Backend docs: backend/README.md"
  echo "   • Frontend docs: frontend/README.md"
  echo "   • Deployment: scripts/DEPLOYMENT_GUIDE.md"
  echo ""
}

# =====================================
# MAIN SCRIPT EXECUTION
# =====================================

print_header "Pottery App - Interactive Deployment"

echo "This script will help you deploy the Pottery App to your local development environment."
echo ""
echo "Note: This version supports LOCAL/DOCKER deployment only."
echo "      Dev/Prod cloud deployment coming in future iterations."
echo ""

# Opening move: Ask what to deploy
echo -e "${YELLOW}What would you like to deploy?${NC}"
echo "  1) Backend Only (Local Docker)"
echo "  2) Frontend Only (Flutter App)"
echo "  3) Both Backend and Frontend"
echo ""

while true; do
  read -p "Enter your choice (1-3): " DEPLOY_CHOICE
  case $DEPLOY_CHOICE in
    1|2|3)
      break
      ;;
    *)
      print_error "Invalid choice. Please enter 1, 2, or 3."
      ;;
  esac
done

echo ""

# Main play: Execute deployment based on choice
DEPLOYED_BACKEND=false
DEPLOYED_FRONTEND=false

case $DEPLOY_CHOICE in
  1)
    deploy_backend_local
    DEPLOYED_BACKEND=true
    ;;
  2)
    deploy_frontend_local
    DEPLOYED_FRONTEND=true
    ;;
  3)
    # Big play: Deploy backend first so app connects to fresh backend
    deploy_backend_local
    DEPLOYED_BACKEND=true
    deploy_frontend_local
    DEPLOYED_FRONTEND=true
    ;;
esac

# Victory lap: Show instructions
show_local_instructions

exit 0
