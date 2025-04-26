#!/bin/bash

# Load environment variables from .env file if it exists
# This allows setting build variables in .env alongside runtime vars
if [ -f "build.env" ]; then
  echo "Loading environment variables from .env file..."
  # Use set -a to export all variables defined in .env
  set -a
  source .env
  set +a
else
  echo "Warning: build.env file not found. Relying on existing environment variables."
fi

# --- Configuration Variables ---
# Ensure GCP_PROJECT_ID is set (should come from .env or environment)
if [ -z "${GCP_PROJECT_ID}" ]; then
  echo "Error: GCP_PROJECT_ID environment variable is not set."
  exit 1
fi
PROJECT_ID="${GCP_PROJECT_ID}"

# Use environment variables for other settings, with defaults
# Use distinct names (e.g., BUILD_*) to avoid potential conflicts
# Default service name: pottery-api
SERVICE_NAME="${BUILD_SERVICE_NAME:-pottery-api}"

# Default region: us-central1
BUILD_REGION="${BUILD_REGION:-us-central1}"

# Default Artifact Registry repo name: pottery-app-repo
REPO_NAME="${BUILD_REPO_NAME:-pottery-app-repo}"

echo "--- Build Configuration ---"
echo "Project ID: ${PROJECT_ID}"
echo "Service Name: ${SERVICE_NAME}"
echo "Region: ${BUILD_REGION}"
echo "Repo Name: ${REPO_NAME}"
echo "---------------------------"

# Replace with the actual path to your key file on your host machine
HOST_KEY_PATH="<path to key file.json>"

# Define where the key will be mounted inside the container
CONTAINER_KEY_PATH="/app/gcp_key.json"

# Build the Docker image
docker build -t pottery-api-image .

# Assuming your built image is tagged 'pottery-api-image'
# Also mount your .env file if needed for other settings
docker --debug run \
  -p 8080:8080 \
  -v "$(pwd)/.env":/app/.env \
  -v "${HOST_KEY_PATH}":"${CONTAINER_KEY_PATH}":ro \
  -e GOOGLE_APPLICATION_CREDENTIALS="${CONTAINER_KEY_PATH}" \
  pottery-api-image