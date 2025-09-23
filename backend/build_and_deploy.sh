#!/bin/bash

# Combined Build and Deploy Script for Cloud Run

# --- Load Environment Variables ---
# Load environment variables ONLY from .env.deploy file if it exists
ENV_DEPLOY_FILE=".env.deploy"
if [ -f "${ENV_DEPLOY_FILE}" ]; then
  echo "Loading environment variables from ${ENV_DEPLOY_FILE} file..."
  # Use set -a to export all variables defined in the file
  set -a
  source "${ENV_DEPLOY_FILE}"
  set +a
else
  # If the primary deploy env file is missing, it's an error.
  echo "Error: ${ENV_DEPLOY_FILE} file not found. Please create it from .env.deploy.example."
  exit 1
fi

# --- Configuration Variables (from .env.deploy) ---
# Ensure required variables are set
if [ -z "${GCP_PROJECT_ID}" ]; then echo "Error: GCP_PROJECT_ID not set in ${ENV_DEPLOY_FILE}." && exit 1; fi
if [ -z "${GCS_BUCKET_NAME}" ]; then echo "Error: GCS_BUCKET_NAME not set in ${ENV_DEPLOY_FILE}." && exit 1; fi
if [ -z "${DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE}" ]; then echo "Error: DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE not set in ${ENV_DEPLOY_FILE}." && exit 1; fi
if [ -z "${DEPLOYMENT_SERVICE_ACCOUNT_EMAIL}" ]; then echo "Error: DEPLOYMENT_SERVICE_ACCOUNT_EMAIL not set in ${ENV_DEPLOY_FILE}." && exit 1; fi
if [ ! -f "${DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE}" ]; then echo "Error: Deployment key file not found at path specified in ${ENV_DEPLOY_FILE}: ${DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE}" && exit 1; fi


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
ENV_VARS="GCP_PROJECT_ID=${PROJECT_ID},GCS_BUCKET_NAME=${GCS_BUCKET}"
# Add optional runtime vars if they are set in .env.deploy
if [ -n "${FIRESTORE_COLLECTION}" ]; then ENV_VARS+=",FIRESTORE_COLLECTION=${FIRESTORE_COLLECTION}"; fi
if [ -n "${FIRESTORE_DATABASE_ID}" ]; then ENV_VARS+=",FIRESTORE_DATABASE_ID=${FIRESTORE_DATABASE_ID}"; fi
if [ -n "${SIGNED_URL_EXPIRATION_MINUTES}" ]; then ENV_VARS+=",SIGNED_URL_EXPIRATION_MINUTES=${SIGNED_URL_EXPIRATION_MINUTES}"; fi


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
gcloud builds submit --tag "${IMAGE_URL}" --project "${PROJECT_ID}"

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

echo "Deployment complete for service ${SERVICE_NAME}."
