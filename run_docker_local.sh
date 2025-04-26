#!/bin/bash

# Script to build and run the Docker container locally

# Load environment variables from .env.local file into the script's environment
ENV_LOCAL_FILE=".env.local"
if [ -f "${ENV_LOCAL_FILE}" ]; then
  echo "Loading environment variables from ${ENV_LOCAL_FILE} file..."
  # Use set -a to export all variables defined in .env.local
  set -a
  source "${ENV_LOCAL_FILE}"
  set +a
else
  echo "Error: ${ENV_LOCAL_FILE} file not found. Please create it from .env.local.example."
  exit 1
fi

# --- Configuration Variables from .env.local ---
# Ensure HOST_KEY_PATH is set for the script
if [ -z "${HOST_KEY_PATH}" ]; then
  echo "Error: HOST_KEY_PATH environment variable is not set in ${ENV_LOCAL_FILE}."
  exit 1
fi
# Use default local port if not set in .env.local
LOCAL_PORT="${LOCAL_PORT:-8000}"
# Get the internal container port (should match Dockerfile EXPOSE and CMD)
# This PORT var is also passed into the container via -e below
CONTAINER_PORT="${PORT:-8080}"

# --- Runtime Variables Needed by the Application Inside the Container ---
# Ensure required runtime variables are set in the loaded environment
if [ -z "${GCP_PROJECT_ID}" ]; then echo "Error: GCP_PROJECT_ID not set in ${ENV_LOCAL_FILE}." && exit 1; fi
if [ -z "${GCS_BUCKET_NAME}" ]; then echo "Error: GCS_BUCKET_NAME not set in ${ENV_LOCAL_FILE}." && exit 1; fi
# Add checks for other required runtime vars if necessary

# Define where the key will be mounted inside the container
CONTAINER_KEY_PATH="/app/gcp_key.json"
# Define the image name
IMAGE_NAME="pottery-api-local-image" # Use a distinct name for local build

echo "--- Local Docker Run Configuration ---"
echo "Host Key Path: ${HOST_KEY_PATH}"
echo "Local Port: ${LOCAL_PORT}"
echo "Container Port: ${CONTAINER_PORT}"
echo "Image Name: ${IMAGE_NAME}"
echo "------------------------------------"


# Build the Docker image
echo "Building Docker image: ${IMAGE_NAME}..."
docker build -t "${IMAGE_NAME}" .
if [ $? -ne 0 ]; then echo "ERROR: Docker build failed." && exit 1; fi
echo "Docker build successful."

# Run the Docker container
echo "Running Docker container..."
docker run --rm -it \
  -p "${LOCAL_PORT}":"${CONTAINER_PORT}" \
  -v "${HOST_KEY_PATH}":"${CONTAINER_KEY_PATH}":ro \
  -e GOOGLE_APPLICATION_CREDENTIALS="${CONTAINER_KEY_PATH}" \
  -e GCP_PROJECT_ID="${GCP_PROJECT_ID}" \
  -e GCS_BUCKET_NAME="${GCS_BUCKET_NAME}" \
  -e FIRESTORE_COLLECTION="${FIRESTORE_COLLECTION:-pottery_items}" \
  -e FIRESTORE_DATABASE_ID="${FIRESTORE_DATABASE_ID:-(default)}" \
  -e SIGNED_URL_EXPIRATION_MINUTES="${SIGNED_URL_EXPIRATION_MINUTES:-15}" \
  -e PORT="${CONTAINER_PORT}" \
  "${IMAGE_NAME}"

# --rm : Automatically remove the container when it exits
# -it  : Run interactively so you see logs and can Ctrl+C
# -p   : Map local port to container port
# -v   : Mount the host key file read-only
# -e   : Set environment variables inside the container
