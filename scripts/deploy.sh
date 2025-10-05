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

# Security checkpoint: Verify gcloud authentication before cloud deployments
check_gcloud_auth() {
  if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI not found"
    print_info "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
  fi

  ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
  if [ -z "$ACTIVE_ACCOUNT" ]; then
    print_error "Not authenticated with gcloud"
    print_info "Run: gcloud auth login"
    exit 1
  fi

  print_success "Authenticated as: $ACTIVE_ACCOUNT"
  echo ""
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
    print_info "Note: 'Installing profile' message is normal - wait 30-60s for completion"
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
# DEV ENVIRONMENT DEPLOYMENT
# =====================================

# Opening move: Deploy backend to Cloud Run dev environment
deploy_backend_dev() {
  print_header "Deploying Backend to Dev (Google Cloud Run)"

  check_gcloud_auth

  print_info "Building and deploying backend to Cloud Run..."
  cd "$BACKEND_SCRIPTS_DIR"
  ./build_and_deploy.sh --env=dev

  print_success "Backend deployed to dev environment!"
  echo ""
}

# Main play: Build and deploy frontend for dev environment
deploy_frontend_dev() {
  print_header "Deploying Frontend (Dev Environment)"

  # Big play: Get Cloud Run dev URL
  DEV_BACKEND_URL="https://pottery-api-dev-1073709451179.us-central1.run.app"
  print_info "Backend URL: $DEV_BACKEND_URL"
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

  # Victory lap: Build and install debug version to USB device
  if [ "$USB_CONNECTED" = true ]; then
    print_info "Building and installing debug version to USB device..."
    FLAVOR=dev API_BASE_URL="$DEV_BACKEND_URL" ./scripts/build_dev.sh debug
    print_success "App installed to USB device as 'Pottery Studio Dev'"
    print_info "Note: 'Installing profile' message is normal - wait 30-60s for completion"
    echo ""
  fi

  # Final whistle: Always build AAB for potential Play Store upload
  print_info "Building AAB (App Bundle)..."
  FLAVOR=dev API_BASE_URL="$DEV_BACKEND_URL" ./scripts/build_dev.sh aab

  AAB_PATH="$FRONTEND_DIR/build/app/outputs/bundle/devRelease/app-dev-release.aab"
  print_success "AAB built successfully!"
  print_info "Location: $AAB_PATH"
  echo ""
}

# Victory lap: Show dev deployment completion info
show_dev_instructions() {
  print_header "Dev Deployment Complete! 🎉"

  echo -e "${GREEN}Your Pottery App (Dev) is ready to use!${NC}"
  echo ""

  if [ "$DEPLOYED_BACKEND" = true ]; then
    echo -e "${CYAN}📦 Backend (Cloud Run - Dev):${NC}"
    echo "   • Running at: https://pottery-api-dev-1073709451179.us-central1.run.app"
    echo "   • API Docs: https://pottery-api-dev-1073709451179.us-central1.run.app/api/docs"
    echo "   • Health check: https://pottery-api-dev-1073709451179.us-central1.run.app/"
    echo "   • Logs: gcloud run services logs read pottery-api-dev --project pottery-app-dev"
    echo ""
  fi

  if [ "$DEPLOYED_FRONTEND" = true ]; then
    echo -e "${CYAN}📱 Frontend (Flutter App - Dev):${NC}"
    if check_usb_device; then
      echo "   • ✅ Installed on USB device: $DEVICE_NAME"
      echo "   • App name: 'Pottery Studio Dev'"
      echo "   • Package: com.pottery.app.dev"
    fi
    echo ""
    echo -e "${CYAN}📦 App Bundle (AAB):${NC}"
    echo "   • Location: frontend/build/app/outputs/bundle/devRelease/app-dev-release.aab"
    echo "   • For: Google Play internal testing track"
    echo "   • Upload via: https://play.google.com/console"
    echo ""
  fi

  echo -e "${CYAN}🧪 Testing Instructions:${NC}"
  echo "   1. On USB device, open 'Pottery Studio Dev' app"
  echo "   2. App connects to Cloud Run dev backend"
  echo "   3. Test with real dev data"
  echo "   4. Create items and verify photo uploads"
  echo ""

  echo -e "${CYAN}📖 Documentation:${NC}"
  echo "   • Deployment guide: scripts/DEPLOYMENT_GUIDE.md"
  echo "   • Backend docs: backend/README.md"
  echo "   • Frontend docs: frontend/README.md"
  echo ""
}

# =====================================
# PROD ENVIRONMENT DEPLOYMENT
# =====================================

# Security checkpoint: Deploy backend to Cloud Run prod with confirmations
deploy_backend_prod() {
  print_header "Deploying Backend to Production (Google Cloud Run)"

  check_gcloud_auth

  # Big play: Safety confirmation for production deployment
  print_warning "You are about to deploy to PRODUCTION!"
  print_info "This will update the live backend serving real users."
  echo ""
  read -p "Type 'DEPLOY TO PROD' to confirm: " CONFIRM

  if [ "$CONFIRM" != "DEPLOY TO PROD" ]; then
    print_error "Deployment cancelled"
    exit 1
  fi
  echo ""

  print_info "Building and deploying backend to Cloud Run..."
  cd "$BACKEND_SCRIPTS_DIR"
  ./build_and_deploy.sh --env=prod

  print_success "Backend deployed to production!"
  echo ""
}

# Main play: Build and deploy frontend for production
deploy_frontend_prod() {
  print_header "Deploying Frontend (Production)"

  # Security checkpoint: Safety confirmation
  print_warning "You are about to build a PRODUCTION app!"
  print_info "This app will connect to the live production backend."
  echo ""
  read -p "Type 'BUILD PROD' to confirm: " CONFIRM

  if [ "$CONFIRM" != "BUILD PROD" ]; then
    print_error "Build cancelled"
    exit 1
  fi
  echo ""

  # Big play: Get Cloud Run prod URL
  PROD_BACKEND_URL="https://pottery-api-prod-4svtnkpwda-uc.a.run.app"
  print_info "Backend URL: $PROD_BACKEND_URL"
  echo ""

  print_info "Production builds are tested via Play Store internal testing"
  print_info "Skipping USB installation (signature conflicts with Play Store)"
  echo ""

  cd "$FRONTEND_DIR"

  # Final whistle: Build production AAB for Play Store
  print_info "Building production AAB (App Bundle)..."
  FLAVOR=prod API_BASE_URL="$PROD_BACKEND_URL" ./scripts/build_prod.sh aab

  AAB_PATH="$FRONTEND_DIR/build/app/outputs/bundle/prodRelease/app-prod-release.aab"
  print_success "Production AAB built successfully!"
  print_info "Location: $AAB_PATH"
  echo ""
}

# Victory lap: Show prod deployment completion info
show_prod_instructions() {
  print_header "Production Deployment Complete! 🎉"

  echo -e "${GREEN}Your Pottery App (Production) is ready!${NC}"
  echo ""

  if [ "$DEPLOYED_BACKEND" = true ]; then
    echo -e "${CYAN}📦 Backend (Cloud Run - Production):${NC}"
    echo "   • Running at: https://pottery-api-1073709451179.us-central1.run.app"
    echo "   • API Docs: https://pottery-api-1073709451179.us-central1.run.app/api/docs"
    echo "   • Health check: https://pottery-api-1073709451179.us-central1.run.app/"
    echo "   • Logs: gcloud run services logs read pottery-api --project pottery-app-prod"
    echo ""
  fi

  if [ "$DEPLOYED_FRONTEND" = true ]; then
    echo -e "${CYAN}📦 Production App Bundle (AAB):${NC}"
    echo "   • Location: frontend/build/app/outputs/bundle/prodRelease/app-prod-release.aab"
    echo "   • For: Google Play production release"
    echo "   • Upload via: https://play.google.com/console"
    echo ""

    echo -e "${YELLOW}⚠️  IMPORTANT - Production Testing Workflow:${NC}"
    echo "   1. Upload AAB to Play Console internal testing track"
    echo "   2. Install from Play Store on test devices"
    echo "   3. Verify backend connectivity to production Cloud Run"
    echo "   4. Test all critical workflows with production data"
    echo "   5. Verify photos upload and display correctly"
    echo "   6. Test with internal testers before promoting to production"
    echo "   7. Monitor backend logs for errors after release"
    echo ""

    echo -e "${CYAN}📝 Why No USB Installation?${NC}"
    echo "   • Production builds are signed with your production keystore"
    echo "   • USB APK would be signed with debug keystore (signature conflict)"
    echo "   • Play Store internal testing provides proper production environment"
    echo "   • Ensures testing matches exact Play Store experience"
    echo ""
  fi

  echo -e "${CYAN}📖 Documentation:${NC}"
  echo "   • Deployment guide: scripts/DEPLOYMENT_GUIDE.md"
  echo "   • Backend docs: backend/README.md"
  echo "   • Frontend docs: frontend/README.md"
  echo ""
}

# =====================================
# MAIN SCRIPT EXECUTION
# =====================================

print_header "Pottery App - Interactive Deployment"

echo "This script will help you deploy the Pottery App across all environments."
echo ""

# Opening move: Ask which environment
echo -e "${YELLOW}Which environment would you like to deploy to?${NC}"
echo "  1) Local/Docker (development on your machine)"
echo "  2) Dev (Google Cloud Run development environment)"
echo "  3) Prod (Google Cloud Run production environment)"
echo ""

while true; do
  read -p "Enter your choice (1-3): " ENV_CHOICE
  case $ENV_CHOICE in
    1|2|3)
      break
      ;;
    *)
      print_error "Invalid choice. Please enter 1, 2, or 3."
      ;;
  esac
done

echo ""

# Set environment based on choice
case $ENV_CHOICE in
  1)
    DEPLOY_ENV="local"
    ;;
  2)
    DEPLOY_ENV="dev"
    ;;
  3)
    DEPLOY_ENV="prod"
    ;;
esac

# Big play: Ask what to deploy
echo -e "${YELLOW}What would you like to deploy?${NC}"
echo "  1) Backend Only"
echo "  2) Frontend Only"
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

# Main play: Execute deployment based on environment and choice
DEPLOYED_BACKEND=false
DEPLOYED_FRONTEND=false

case $DEPLOY_ENV in
  local)
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
    show_local_instructions
    ;;
  dev)
    case $DEPLOY_CHOICE in
      1)
        deploy_backend_dev
        DEPLOYED_BACKEND=true
        ;;
      2)
        deploy_frontend_dev
        DEPLOYED_FRONTEND=true
        ;;
      3)
        deploy_backend_dev
        DEPLOYED_BACKEND=true
        deploy_frontend_dev
        DEPLOYED_FRONTEND=true
        ;;
    esac
    show_dev_instructions
    ;;
  prod)
    case $DEPLOY_CHOICE in
      1)
        deploy_backend_prod
        DEPLOYED_BACKEND=true
        ;;
      2)
        deploy_frontend_prod
        DEPLOYED_FRONTEND=true
        ;;
      3)
        deploy_backend_prod
        DEPLOYED_BACKEND=true
        deploy_frontend_prod
        DEPLOYED_FRONTEND=true
        ;;
    esac
    show_prod_instructions
    ;;
esac

exit 0
