#!/bin/bash

# Combined Build and Deploy Script

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
  echo "Loading environment variables from .env file..."
  set -a
  source .env
  set +a
else
  echo "Warning: .env file not found. Relying on existing environment variables."
fi

# Load build/deployment environment variables from build.env file if it exists
if [ -f "build.env" ]; then
  echo "Loading environment variables from build.env file..."
  set -a
  source build.env
  set +a
else
  echo "Warning: build.env file not found. Relying on existing environment variables."
fi

# --- Configuration Variables ---
# Ensure GCP_PROJECT_ID is set
if [ -z "${GCP_PROJECT_ID}" ]; then
  echo "Error: GCP_PROJECT_ID environment variable is not set."
  exit 1
fi
PROJECT_ID="${GCP_PROJECT_ID}"

# Set defaults for Build/Deploy parameters if not provided
SERVICE_NAME="${BUILD_SERVICE_NAME:-pottery-api}"
BUILD_REGION="${BUILD_REGION:-us-central1}"
REPO_NAME="${BUILD_REPO_NAME:-pottery-app-repo}"

# Construct the image URL (used for both tagging the build and deploying)
IMAGE_URL="${BUILD_REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}:latest"

# Runtime Service Account for Cloud Run
CLOUD_RUN_SERVICE_ACCOUNT_EMAIL="${CLOUD_RUN_SERVICE_ACCOUNT_EMAIL:-pottery-app-sa@${PROJECT_ID}.iam.gserviceaccount.com}"

# Deployment Service Account (needs permissions for Build, AR, Run, IAM)
if [ -z "${DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE}" ] || [ -z "${DEPLOYMENT_SERVICE_ACCOUNT_EMAIL}" ]; then
  echo "Error: DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE or DEPLOYMENT_SERVICE_ACCOUNT_EMAIL is not set."
  echo "Please set these in build.env or your environment."
  exit 1
fi

# Runtime GCS Bucket
if [ -z "${GCS_BUCKET_NAME}" ]; then
  echo "Error: GCS_BUCKET_NAME environment variable (for runtime) is not set."
  exit 1
fi
GCS_BUCKET="${GCS_BUCKET_NAME}"

# Construct the runtime environment variables string for Cloud Run
ENV_VARS="GCP_PROJECT_ID=${PROJECT_ID},GCS_BUCKET_NAME=${GCS_BUCKET}"
# Add other optional runtime vars if set
# Example: if [ -n "${FIRESTORE_COLLECTION}" ]; then ENV_VARS+=",FIRESTORE_COLLECTION=${FIRESTORE_COLLECTION}"; fi


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
