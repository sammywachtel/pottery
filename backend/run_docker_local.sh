#!/bin/bash

# Script to build and run the Docker container locally
# Usage: ./run_docker_local.sh [--debug] [--env=<environment>]

# Parse command line arguments
DEBUG_MODE=false
ENVIRONMENT="dev"  # Default to development
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --debug) DEBUG_MODE=true; shift ;;
    --env=*)
      ENVIRONMENT="${1#*=}"
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--debug] [--env=<environment>]"
      echo "Options:"
      echo "  --debug        Enable remote debugging on port 5678"
      echo "  --env=ENV      Environment to use (dev|local, default: dev)"
      echo "  --help         Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                    # Run with dev environment"
      echo "  $0 --debug           # Run with debug mode enabled"
      echo "  $0 --env=local       # Use legacy .env.local file"
      exit 0
      ;;
    *) echo "Unknown parameter: $1"; echo "Use --help for usage information"; exit 1 ;;
  esac
done

# Determine environment file
case $ENVIRONMENT in
  dev|development)
    ENV_FILE=".env.dev"
    echo "🚀 Running with DEVELOPMENT environment"
    ;;
  local)
    ENV_FILE=".env.local"
    echo "🔧 Running with LEGACY local environment"
    ;;
  *)
    echo "Error: Invalid environment '$ENVIRONMENT'. Use 'dev' or 'local'."
    exit 1
    ;;
esac

# Load environment variables from environment file into the script's environment
if [ -f "${ENV_FILE}" ]; then
  echo "Loading environment variables from ${ENV_FILE} file..."
  # Use set -a to export all variables defined in the file
  set -a
  source "${ENV_FILE}"
  set +a
else
  echo "Error: ${ENV_FILE} file not found."
  echo "Available files:"
  ls -la .env.* 2>/dev/null || echo "No .env files found"
  exit 1
fi

# --- Configuration Variables from environment file ---
# Ensure HOST_KEY_PATH is set for the script
if [ -z "${HOST_KEY_PATH}" ]; then
  echo "Error: HOST_KEY_PATH environment variable is not set in ${ENV_FILE}."
  exit 1
fi
# Use default local port if not set in .env.local
LOCAL_PORT="${LOCAL_PORT:-8000}"
# Get the internal container port (should match Dockerfile EXPOSE and CMD)
# This PORT var is also passed into the container via -e below
CONTAINER_PORT="${PORT:-8080}"
# Debug port for PyCharm
DEBUG_PORT="${DEBUG_PORT:-5678}"

# Show local development summary
echo "📋 Local Development Summary:"
echo "   Environment: ${ENVIRONMENT}"
echo "   Config File: ${ENV_FILE}"
echo "   GCP Project: ${GCP_PROJECT_ID}"
echo "   Local Port: ${LOCAL_PORT}"
echo "   Debug Mode: ${DEBUG_MODE}"

# --- Runtime Variables Needed by the Application Inside the Container ---
# Ensure required runtime variables are set in the loaded environment
if [ -z "${GCP_PROJECT_ID}" ]; then echo "Error: GCP_PROJECT_ID not set in ${ENV_FILE}." && exit 1; fi
if [ -z "${GCS_BUCKET_NAME}" ]; then echo "Error: GCS_BUCKET_NAME not set in ${ENV_FILE}." && exit 1; fi
# Add checks for other required runtime vars if necessary

# Define where the key will be mounted inside the container
CONTAINER_KEY_PATH="/app/gcp_key.json"
# Define the image and container names
IMAGE_NAME="pottery-api-local-image" # Use a distinct name for local build
CONTAINER_NAME="pottery-backend" # Consistent container name

echo "--- Local Docker Run Configuration ---"
echo "Host Key Path: ${HOST_KEY_PATH}"
echo "Local Port: ${LOCAL_PORT}"
echo "Container Port: ${CONTAINER_PORT}"
echo "Debug Port: ${DEBUG_PORT}"
echo "Debug Mode: ${DEBUG_MODE}"
echo "Image Name: ${IMAGE_NAME}"
echo "Container Name: ${CONTAINER_NAME}"
echo "------------------------------------"


# Stop and remove any existing container with the same name
echo "Checking for existing container: ${CONTAINER_NAME}..."
if [ "$(docker ps -q -f name=^${CONTAINER_NAME}$)" ]; then
    echo "Stopping running container: ${CONTAINER_NAME}..."
    docker stop ${CONTAINER_NAME}
fi
if [ "$(docker ps -aq -f name=^${CONTAINER_NAME}$)" ]; then
    echo "Removing existing container: ${CONTAINER_NAME}..."
    docker rm ${CONTAINER_NAME}
fi

# Build the Docker image
echo "Building Docker image: ${IMAGE_NAME}..."
docker build -t "${IMAGE_NAME}" .
if [ $? -ne 0 ]; then echo "ERROR: Docker build failed." && exit 1; fi
echo "Docker build successful."

# Setup local infrastructure (including CORS)
echo "Setting up local development infrastructure..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_SCRIPT="${SCRIPT_DIR}/scripts/setup-infrastructure.sh"

if [ -x "${INFRA_SCRIPT}" ]; then
  echo "Configuring GCS bucket CORS for local development..."
  "${INFRA_SCRIPT}" local
else
  echo "WARNING: Infrastructure setup script not found at ${INFRA_SCRIPT}"
  echo "You may need to manually configure GCS bucket CORS settings."
  echo "Run: ./scripts/manage-cors.sh apply local"
fi

# Run the Docker container
echo "Running Docker container..."

# Base docker run command with common options
DOCKER_CMD="docker run --name ${CONTAINER_NAME} -d \
  -p ${LOCAL_PORT}:${CONTAINER_PORT} \
  -v ${HOST_KEY_PATH}:${CONTAINER_KEY_PATH}:ro \
  -e GOOGLE_APPLICATION_CREDENTIALS=${CONTAINER_KEY_PATH} \
  -e GCP_PROJECT_ID=${GCP_PROJECT_ID} \
  -e GCS_BUCKET_NAME=${GCS_BUCKET_NAME} \
  -e FIRESTORE_COLLECTION=${FIRESTORE_COLLECTION:-pottery_items} \
  -e FIRESTORE_DATABASE_ID=${FIRESTORE_DATABASE_ID:-(default)} \
  -e SIGNED_URL_EXPIRATION_MINUTES=${SIGNED_URL_EXPIRATION_MINUTES:-15} \
  -e FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID} \
  -e FIREBASE_CREDENTIALS_FILE=${CONTAINER_KEY_PATH} \
  -e PORT=${CONTAINER_PORT}"

# Add debug port mapping and command if in debug mode
if [ "$DEBUG_MODE" = true ]; then
  echo "🐛 Starting container in debug mode..."
  # Add debug port mapping
  DOCKER_CMD="${DOCKER_CMD} -p ${DEBUG_PORT}:5678"
  # Run with debugpy (override the default CMD)
  ${DOCKER_CMD} ${IMAGE_NAME} python -Xfrozen_modules=off -m debugpy --listen 0.0.0.0:5678 --wait-for-client -m uvicorn main:app --host 0.0.0.0 --port ${CONTAINER_PORT} --reload
else
  # Run normally using the default CMD from Dockerfile
  echo "🚀 Starting container in normal mode..."
  ${DOCKER_CMD} ${IMAGE_NAME}
fi

# --name : Give the container a consistent name for easy management
# -it    : Run interactively so you see logs and can Ctrl+C
# -p     : Map local port to container port
# -v     : Mount the host key file read-only
# -e     : Set environment variables inside the container
#
# Note: Container is NOT automatically removed (no --rm flag)
# This allows for easier debugging and consistent container naming
# Previous containers with the same name are automatically cleaned up
