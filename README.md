# Pottery Catalog API

## Overview

This project provides a RESTful API for managing a catalog of pottery items. It uses FastAPI as the web framework, Google Firestore for storing item metadata, and Google Cloud Storage (GCS) for storing associated photos. Access to photos is provided via temporary signed URLs generated on demand.

The application is designed to be containerized using Docker and deployed to Google Cloud Run.

## Features

* **CRUD Operations for Items:** Create, Read, Update, and Delete pottery item metadata (name, clay type, location, notes, measurements, created date/time).
* **Photo Management:** Upload photos associated with specific items, update photo metadata (stage, notes), and delete photos.
* **Secure Photo Access:** Photos are stored privately in GCS, and access is granted via short-lived Signed URLs included in API responses.
* **Timezone Awareness:** Stores creation/upload timestamps in UTC while preserving the original client timezone information.
* **Automatic API Documentation:** Interactive documentation (Swagger UI and ReDoc) generated automatically by FastAPI.
* **Containerized Deployment:** Includes a Dockerfile ready for building and deploying on Google Cloud Run or other container platforms.

## Technology Stack

* **Backend Framework:** FastAPI
* **Database:** Google Cloud Firestore (Native Mode)
* **Storage:** Google Cloud Storage (GCS)
* **Containerization:** Docker
* **Configuration:** Pydantic Settings (via Environment Variables / `.env` file)
* **Testing:** Pytest, pytest-asyncio, pytest-mock

## Project Structure

```
.
├── .env                  # Optional: For local environment variables (add to .gitignore!)
├── .env.example          # Example environment variables
├── Dockerfile            # Container definition
├── requirements.txt      # Python dependencies
├── requirements-dev.txt  # Development/test dependencies
├── config.py             # Application settings/configuration
├── main.py               # FastAPI app entry point and global handlers
├── models.py             # Pydantic data models (incl. internal and response models)
├── pytest.ini            # Pytest configuration (e.g., markers)
├── README.md             # This file
├── routers/
│   ├── __init__.py
│   ├── items.py          # Router for /api/items endpoints
│   └── photos.py         # Router for /api/items/{item_id}/photos endpoints
├── services/
│   ├── __init__.py
│   ├── firestore_service.py # Logic for Firestore interactions
│   └── gcs_service.py      # Logic for GCS interactions (incl. signed URL generation)
└── tests/
    ├── __init__.py
    ├── conftest.py         # Root test fixtures (e.g., TestClient)
    ├── test_main.py        # Unit tests for main app
    ├── test_items_router.py # Unit tests for items router
    ├── test_photos_router.py# Unit tests for photos router
    ├── images/             # Directory for test images
    │   └── crackle.jpeg    # Example test image
    └── integration/        # Integration tests
        ├── __init__.py
        ├── conftest.py     # Integration test fixtures (e.g., resource cleanup)
        └── test_integration_items_photos.py # Tests interacting with GCP
```

## Setup and Local Development

### Prerequisites

* Python 3.10+
* `pip` (Python package installer)
* Google Cloud SDK (`gcloud`) installed and authenticated (for Application Default Credentials)
* Docker (optional, if building images locally)
* Access to a Google Cloud Project with Firestore (Native Mode) and Cloud Storage enabled.

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd <repository-directory>
```

### 2. Set Up Environment Variables

* Copy the example environment file:
    ```bash
    cp .env.example .env
    ```
* Edit the `.env` file and provide your specific Google Cloud configuration:
    * `GCP_PROJECT_ID`: Your Google Cloud project ID.
    * `GCS_BUCKET_NAME`: The name of the GCS bucket to use for photo storage. **Ensure this bucket exists.**
    * `FIRESTORE_COLLECTION`: (Optional) Name for the Firestore collection (defaults to `pottery_items`).
    * `FIRESTORE_DATABASE_ID`: (Optional) Firestore database ID if not using `(default)`.
* **Important:** Add `.env` to your `.gitignore` file to avoid committing secrets.
* **Authentication (Local):** For local development, authenticate the Google Cloud SDK to provide Application Default Credentials (ADC). The easiest way is often:
    ```bash
    gcloud auth application-default login
    ```
    Alternatively, download a service account key file (with Firestore and GCS permissions) and set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to its path (e.g., `export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/keyfile.json"`).

### 3. Install Dependencies

```bash
# Install application dependencies
pip install -r requirements.txt

# Install development/testing dependencies
pip install -r requirements-dev.txt
```

### 4. Run the Application Locally

```bash
python main.py
```
Or using uvicorn for auto-reload:
```bash
uvicorn main:app --reload --port 8000
```
(Replace `8000` with the desired port, although it defaults to 8080 or the `PORT` value in `.env`).

### 5. Access API Documentation

Once the server is running, access the interactive API documentation (Swagger UI) in your browser:

* [http://localhost:8080/api/docs](http://localhost:8080/api/docs) (Adjust port if necessary)

You can also view the ReDoc documentation at `/api/redoc`.

## API Endpoints Summary

The API provides endpoints for managing pottery items and their photos. Key endpoints include:

* `GET /`: Health check.
* `GET /api/items`: List all pottery items.
* `POST /api/items`: Create a new pottery item.
* `GET /api/items/{item_id}`: Get a specific item by ID.
* `PUT /api/items/{item_id}`: Update an item's metadata.
* `DELETE /api/items/{item_id}`: Delete an item and its photos.
* `POST /api/items/{item_id}/photos`: Upload a photo for an item.
* `PUT /api/items/{item_id}/photos/{photo_id}`: Update a photo's metadata.
* `DELETE /api/items/{item_id}/photos/{photo_id}`: Delete a specific photo.

For detailed request/response schemas and to try out the API, please refer to the interactive documentation at `/api/docs`.

## Testing

### Unit Tests

These tests mock external services (Firestore, GCS) and verify the API logic in isolation.

```bash
# Run all tests except integration tests
pytest -m "not integration"
```
Or (if not using markers):
```bash
pytest --ignore=tests/integration
```

### Integration Tests

These tests interact with **real** Google Cloud services specified in your test configuration. **Ensure you are configured to use a non-production test environment.** Create the `tests/images` directory and place a `crackle.jpeg` file inside it before running.

```bash
# Ensure test environment variables and ADC are set correctly first!
# Run only integration tests
pytest -m integration
```
Or (if not using markers):
```bash
pytest tests/integration/
```

## Deployment to Google Cloud Run

### Prerequisites

* Google Cloud SDK (`gcloud`) configured and authenticated with permissions to manage Cloud Run, Cloud Build, Artifact Registry (or GCR), Firestore, and GCS.
* Required GCP APIs enabled (Cloud Run, Cloud Build, Artifact Registry, Firestore, Cloud Storage).
* A Service Account for the Cloud Run service with appropriate IAM roles (e.g., Firestore User, Storage Object Admin, Cloud Storage Service Agent (for signed URLs)).

### 1. Build the Docker Image

You can use Google Cloud Build to build the image directly from your source code and push it to Artifact Registry (recommended) or Google Container Registry (GCR).

```bash
# --- Replace placeholders ---
PROJECT_ID="your-gcp-project-id"
SERVICE_NAME="pottery-api" # Or your desired service name
REGION="your-gcp-region" # e.g., us-central1
REPO_NAME="your-artifact-registry-repo-name" # e.g., pottery-app-repo

# --- Build and Push Command (Using Artifact Registry) ---
gcloud builds submit --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}:latest --project ${PROJECT_ID}

# --- Build and Push Command (Using Google Container Registry - GCR) ---
# gcloud builds submit --tag gcr.io/${PROJECT_ID}/${SERVICE_NAME}:latest --project ${PROJECT_ID}
```

### 2. Deploy to Cloud Run

Deploy the container image using the `gcloud run deploy` command. This example script sets common options; adapt as needed.

```bash
# --- Replace placeholders ---
PROJECT_ID="your-gcp-project-id"
SERVICE_NAME="pottery-api" # Or your desired service name
REGION="your-gcp-region" # e.g., us-central1
# Use the image URL from Artifact Registry or GCR (must match the build step)
IMAGE_URL="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}:latest"
# IMAGE_URL="gcr.io/${PROJECT_ID}/${SERVICE_NAME}:latest" # GCR example

# Service account for Cloud Run instance (must have Firestore/GCS permissions)
# Create one if needed: gcloud iam service-accounts create ...
SERVICE_ACCOUNT_EMAIL="your-cloud-run-service-account@${PROJECT_ID}.iam.gserviceaccount.com"

# --- Required Environment Variables ---
GCS_BUCKET="your-gcs-bucket-name-for-photos" # Bucket used by the deployed app
# Optional (defaults are often fine)
# FS_COLLECTION="pottery_items"
# FS_DB_ID="(default)"
# SIGNED_URL_MINS="15"

# Construct the environment variables string for gcloud command
# Always include GCP_PROJECT_ID for clarity within the app/clients
ENV_VARS="GCP_PROJECT_ID=${PROJECT_ID}"
ENV_VARS+=",GCS_BUCKET_NAME=${GCS_BUCKET}"
# Add optional vars if needed:
# ENV_VARS+=",FIRESTORE_COLLECTION=${FS_COLLECTION}"
# ENV_VARS+=",FIRESTORE_DATABASE_ID=${FS_DB_ID}"
# ENV_VARS+=",SIGNED_URL_EXPIRATION_MINUTES=${SIGNED_URL_MINS}"

# --- Deploy Command ---
gcloud run deploy ${SERVICE_NAME} \
    --image ${IMAGE_URL} \
    --platform managed \
    --region ${REGION} \
    --service-account ${SERVICE_ACCOUNT_EMAIL} \
    --set-env-vars "${ENV_VARS}" \
    --allow-unauthenticated \
    --project ${PROJECT_ID}

# Note: --allow-unauthenticated makes the API public.
# For private APIs, use --no-allow-unauthenticated and configure IAM/IAP for access control.
```

After deployment, Cloud Run will provide a service URL where your API will be accessible.
