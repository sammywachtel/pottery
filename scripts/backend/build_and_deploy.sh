#!/bin/bash

# Combined Build and Deploy Script for Cloud Run
# Usage: ./build_and_deploy.sh [--env=<environment>]
# Environments: dev (default), prod

# Calculate directory paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BACKEND_DIR="${PROJECT_ROOT}/backend"

# --- Parse Command Line Arguments ---
ENVIRONMENT="dev"  # Default to development
while [[ $# -gt 0 ]]; do
  case $1 in
    --env=*)
      ENVIRONMENT="${1#*=}"
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--env=<environment>]"
      echo "Environments: dev (default), prod"
      echo "Examples:"
      echo "  $0                # Deploy to dev environment"
      echo "  $0 --env=dev      # Deploy to dev environment"
      echo "  $0 --env=prod     # Deploy to production"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# --- Validate Environment ---
case $ENVIRONMENT in
  dev|development)
    ENV_FILE="${BACKEND_DIR}/.env.dev"
    echo "🚀 Deploying to DEVELOPMENT environment"
    ;;
  prod|production)
    ENV_FILE="${BACKEND_DIR}/.env.prod"
    echo "🏭 Deploying to PRODUCTION environment"
    ;;
  *)
    echo "Error: Invalid environment '$ENVIRONMENT'. Use 'dev' or 'prod'."
    exit 1
    ;;
esac

# --- Load Environment Variables ---
if [ -f "${ENV_FILE}" ]; then
  echo "Loading environment variables from ${ENV_FILE}..."
  # Use set -a to export all variables defined in the file
  set -a
  source "${ENV_FILE}"
  set +a
else
  echo "Error: Environment file ${ENV_FILE} not found."
  echo "Available files in backend directory:"
  ls -la "${BACKEND_DIR}"/.env.* 2>/dev/null || echo "No .env files found"
  exit 1
fi

# --- Configuration Variables (from environment file) ---
# Ensure required variables are set
if [ -z "${GCP_PROJECT_ID}" ]; then echo "Error: GCP_PROJECT_ID not set in ${ENV_FILE}." && exit 1; fi
if [ -z "${GCS_BUCKET_NAME}" ]; then echo "Error: GCS_BUCKET_NAME not set in ${ENV_FILE}." && exit 1; fi
if [ -z "${DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE}" ]; then echo "Error: DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE not set in ${ENV_FILE}." && exit 1; fi
if [ -z "${DEPLOYMENT_SERVICE_ACCOUNT_EMAIL}" ]; then echo "Error: DEPLOYMENT_SERVICE_ACCOUNT_EMAIL not set in ${ENV_FILE}." && exit 1; fi
if [ ! -f "${DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE}" ]; then echo "Error: Deployment key file not found at path specified in ${ENV_FILE}: ${DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE}" && exit 1; fi

# Show deployment summary
echo "📋 Deployment Summary:"
echo "   Environment: ${ENVIRONMENT}"
echo "   Config File: ${ENV_FILE}"
echo "   GCP Project: ${GCP_PROJECT_ID}"
echo "   Service Name: ${BUILD_SERVICE_NAME:-pottery-api}"
echo "   Build Region: ${BUILD_REGION:-us-central1}"


PROJECT_ID="${GCP_PROJECT_ID}"
# Set defaults for optional Build/Deploy parameters if not provided
SERVICE_NAME="${BUILD_SERVICE_NAME:-pottery-api}"
BUILD_REGION="${BUILD_REGION:-us-central1}"
REPO_NAME="${BUILD_REPO_NAME:-pottery-app-repo}"

# Construct the image URL (used for both tagging the build and deploying)
IMAGE_URL="${BUILD_REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}:latest"

# Runtime Service Account for Cloud Run (use default if not set in .env.deploy)
CLOUD_RUN_SERVICE_ACCOUNT_EMAIL="${CLOUD_RUN_SERVICE_ACCOUNT_EMAIL:-pottery-app-sa@${PROJECT_ID}.iam.gserviceaccount.com}"

# Runtime GCS Bucket (already checked above)
GCS_BUCKET="${GCS_BUCKET_NAME}"

# Construct the runtime environment variables string for Cloud Run deployment
# Required vars
ENV_VARS="ENVIRONMENT=${ENVIRONMENT},GCP_PROJECT_ID=${PROJECT_ID},GCS_BUCKET_NAME=${GCS_BUCKET}"
# Add optional runtime vars if they are set in environment file
if [ -n "${FIRESTORE_COLLECTION}" ]; then ENV_VARS+=",FIRESTORE_COLLECTION=${FIRESTORE_COLLECTION}"; fi
if [ -n "${FIRESTORE_DATABASE_ID}" ]; then ENV_VARS+=",FIRESTORE_DATABASE_ID=${FIRESTORE_DATABASE_ID}"; fi
if [ -n "${SIGNED_URL_EXPIRATION_MINUTES}" ]; then ENV_VARS+=",SIGNED_URL_EXPIRATION_MINUTES=${SIGNED_URL_EXPIRATION_MINUTES}"; fi
if [ -n "${FIREBASE_PROJECT_ID}" ]; then ENV_VARS+=",FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}"; fi
if [ -n "${FIREBASE_AUTH_DOMAIN}" ]; then ENV_VARS+=",FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN}"; fi
if [ -n "${JWT_SECRET_KEY}" ]; then ENV_VARS+=",JWT_SECRET_KEY=${JWT_SECRET_KEY}"; fi


echo "--- Build & Deploy Configuration ---"
echo "Project ID: ${PROJECT_ID}"
echo "Service Name: ${SERVICE_NAME}"
echo "Region: ${BUILD_REGION}"
echo "Repo Name: ${REPO_NAME}"
echo "Image URL: ${IMAGE_URL}"
echo "Cloud Run Service Account: ${CLOUD_RUN_SERVICE_ACCOUNT_EMAIL}"
echo "Deployment Service Account: ${DEPLOYMENT_SERVICE_ACCOUNT_EMAIL}"
echo "Runtime Environment Variables: ${ENV_VARS}"
echo "----------------------------------"

# --- Authenticate with Deployment Service Account ---
# This account needs permissions for: Cloud Build, Artifact Registry, Cloud Run, IAM Service Account User
echo "Authenticating with deployment service account: ${DEPLOYMENT_SERVICE_ACCOUNT_EMAIL}"
gcloud auth activate-service-account "${DEPLOYMENT_SERVICE_ACCOUNT_EMAIL}" --key-file="${DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE}" --project="${PROJECT_ID}"
if [ $? -ne 0 ]; then echo "ERROR: Failed to authenticate deployment service account." && exit 1; fi

# --- Ensure Artifact Registry Repository Exists ---
echo "Checking for Artifact Registry repository: ${REPO_NAME} in region ${BUILD_REGION}..."
gcloud artifacts repositories describe "${REPO_NAME}" \
  --project="${PROJECT_ID}" \
  --location="${BUILD_REGION}" \
  --format="value(name)" > /dev/null 2>&1 # Suppress output

if [ $? -ne 0 ]; then
  echo "Repository '${REPO_NAME}' not found. Creating it..."
  # Note: Deployment SA needs roles/artifactregistry.admin permission
  gcloud artifacts repositories create "${REPO_NAME}" \
    --project="${PROJECT_ID}" \
    --repository-format="docker" \
    --location="${BUILD_REGION}" \
    --description="Docker repository for ${SERVICE_NAME} service"

  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create Artifact Registry repository '${REPO_NAME}'."
    echo "Ensure the deployment service account (${DEPLOYMENT_SERVICE_ACCOUNT_EMAIL}) has the 'Artifact Registry Administrator' role."
    exit 1
  else
    echo "Repository '${REPO_NAME}' created successfully."
  fi
else
  echo "Repository '${REPO_NAME}' already exists."
fi

# --- Build and Push Docker Image using Cloud Build ---
echo "Submitting build to Cloud Build for image: ${IMAGE_URL}"
# Note: The *deployment* SA needs roles/cloudbuild.builds.editor to trigger builds.
# Note: Cloud Build's *own* service account ([PROJECT_NUMBER]@cloudbuild.gserviceaccount.com)
# needs roles/artifactregistry.writer to push the image to the repo.
gcloud builds submit --tag "${IMAGE_URL}" --project "${PROJECT_ID}" "${BACKEND_DIR}"

# Check if the build succeeded
if [ $? -ne 0 ]; then
  echo "ERROR: Cloud Build failed. Check Cloud Build logs in GCP Console."
  exit 1
fi
echo "Build successful. Image pushed to: ${IMAGE_URL}"


# --- Deploy Image to Cloud Run ---
echo "Deploying image ${IMAGE_URL} to Cloud Run service ${SERVICE_NAME}..."
# Note: The *deployment* SA needs roles/run.admin and roles/iam.serviceAccountUser (to act as runtime SA)
gcloud run deploy "${SERVICE_NAME}" \
    --image "${IMAGE_URL}" \
    --platform managed \
    --region "${BUILD_REGION}" \
    --service-account "${CLOUD_RUN_SERVICE_ACCOUNT_EMAIL}" \
    --set-env-vars "${ENV_VARS}" \
    --allow-unauthenticated \
    --project "${PROJECT_ID}" \
    --verbosity=info # Use info or debug for more output

if [ $? -ne 0 ]; then echo "ERROR: Cloud Run deployment failed." && exit 1; fi

echo "Deployment successful for service ${SERVICE_NAME}."

# --- Setup Infrastructure Components ---
echo "Setting up infrastructure components..."
INFRA_SCRIPT="${SCRIPT_DIR}/setup-infrastructure.sh"

if [ -x "${INFRA_SCRIPT}" ]; then
  echo "Configuring GCS bucket CORS for production..."
  "${INFRA_SCRIPT}" prod
  echo "Infrastructure setup completed."
else
  echo "WARNING: Infrastructure setup script not found at ${INFRA_SCRIPT}"
  echo "You may need to manually configure GCS bucket CORS settings."
fi

echo "Deployment complete for service ${SERVICE_NAME}."

# --- Fix Signed URLs ---
# Victory lap: configure signed URL generation to work properly in Cloud Run
echo ""
echo "Configuring signed URL generation..."
FIX_URLS_SCRIPT="${SCRIPT_DIR}/fix-signed-urls.sh"

if [ -x "${FIX_URLS_SCRIPT}" ]; then
  echo "Running signed URL fix for ${ENVIRONMENT} environment..."
  "${FIX_URLS_SCRIPT}" --env="${ENVIRONMENT}"
  echo "Signed URL configuration completed."
else
  echo "WARNING: Signed URL fix script not found at ${FIX_URLS_SCRIPT}"
  echo "You may need to manually run: ${SCRIPT_DIR}/fix-signed-urls.sh --env=${ENVIRONMENT}"
fi

echo ""
echo "🎉 Full deployment complete for ${ENVIRONMENT} environment!"
