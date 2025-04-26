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
├── build.env             # Optional: For build/deployment specific variables
├── Dockerfile            # Container definition
├── requirements.txt      # Python dependencies
├── requirements-dev.txt  # Development/test dependencies
├── config.py             # Application settings/configuration
├── main.py               # FastAPI app entry point and global handlers
├── models.py             # Pydantic data models (incl. internal and response models)
├── pytest.ini            # Pytest configuration (e.g., markers)
├── README.md             # This file
├── build_docker_image.sh # Script to build and push Docker image
├── deploy.sh             # Script to deploy image to Cloud Run
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
* Edit the `.env` file and provide your specific Google Cloud configuration for **runtime**:
    * `GCP_PROJECT_ID`: Your Google Cloud project ID. **(Required)**
    * `GCS_BUCKET_NAME`: The name of the GCS bucket to use for photo storage. **Ensure this bucket exists.** **(Required)**
    * `FIRESTORE_COLLECTION`: (Optional) Name for the Firestore collection (defaults to `pottery_items`).
    * `FIRESTORE_DATABASE_ID`: (Optional) Firestore database ID if not using `(default)`.
    * `SIGNED_URL_EXPIRATION_MINUTES`: (Optional) Validity duration for photo URLs (defaults to 15).
    * `PORT`: (Optional) Port for the local Uvicorn server (defaults to 8080).
* Create a `build.env` file (or set environment variables directly) for **build/deployment**:
    * `GCP_PROJECT_ID`: Your Google Cloud project ID. **(Required)**
    * `BUILD_SERVICE_NAME`: (Optional) Name for the Cloud Run service / Docker image tag (defaults to `pottery-api`).
    * `BUILD_REGION`: (Optional) GCP region for Artifact Registry / Cloud Build (defaults to `us-central1`).
    * `BUILD_REPO_NAME`: (Optional) Artifact Registry repository name (defaults to `pottery-app-repo`).
    * `CLOUD_RUN_SERVICE_ACCOUNT_EMAIL`: (Optional) Email of the service account the Cloud Run service will run as (defaults to `pottery-app-sa@[PROJECT_ID].iam.gserviceaccount.com`). Needs Firestore/GCS permissions.
    * `DEPLOYMENT_SERVICE_ACCOUNT_EMAIL`: **(Required)** Email of the service account used to run the deployment script. Needs Artifact Registry Admin, Cloud Run Admin, IAM Service Account User roles.
    * `DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE`: **(Required)** Path to the JSON key file for the deployment service account.
* **Important:** Add `.env` and `build.env` (and any key files) to your `.gitignore` file.
* **Authentication (Local):** For running the app locally (not deploying), authenticate the Google Cloud SDK:
    ```bash
    gcloud auth application-default login
    ```
    Or set `GOOGLE_APPLICATION_CREDENTIALS` to a key file path.

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
uvicorn main:app --reload --port ${PORT:-8000}
```

### 5. Access API Documentation

Once the server is running, access the interactive API documentation (Swagger UI) in your browser:

* [http://localhost:${PORT:-8000}/api/docs](http://localhost:${PORT:-8000}/api/docs)

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

* Google Cloud SDK (`gcloud`) configured.
* Required GCP APIs enabled (Cloud Run, Cloud Build, Artifact Registry, Firestore, Cloud Storage).
* An Artifact Registry repository created (or use GCR). **Note:** The `deploy.sh` script can now create this if it doesn't exist.
* A Service Account for the Cloud Run service (e.g., `pottery-app-sa@[PROJECT_ID].iam.gserviceaccount.com`) with roles like `Firestore User`, `Storage Object Admin`, `Cloud Storage Service Agent`.
* A separate Service Account for **running the deployment** (e.g., `deployer-sa@[PROJECT_ID].iam.gserviceaccount.com`) with roles like `Artifact Registry Administrator` (to create repo), `Cloud Run Admin`, `IAM Service Account User` (to act as the Cloud Run SA during deployment). You need to download a key file for this deployer service account.

### 1. Build the Docker Image

Use the provided `build_docker_image.sh` script.

**Build Script Variables:**

Configure these in `build.env` or your environment:

* `GCP_PROJECT_ID`: **(Required)** Your Google Cloud project ID.
* `BUILD_SERVICE_NAME`: (Optional) Defaults to `pottery-api`.
* `BUILD_REGION`: (Optional) Defaults to `us-central1`.
* `BUILD_REPO_NAME`: (Optional) Defaults to `pottery-app-repo`.

**Run the Build Script:**

```bash
# Authenticate gcloud if needed for Cloud Build permissions
# gcloud auth application-default login OR gcloud auth login
chmod +x build_docker_image.sh
./build_docker_image.sh
```

### 2. Deploy to Cloud Run

Use the provided `deploy.sh` script.

**Deployment Script Variables:**

Configure these in `build.env` or your environment:

* `GCP_PROJECT_ID`: **(Required)** Your Google Cloud project ID.
* `GCS_BUCKET_NAME`: **(Required)** The runtime GCS bucket name.
* `BUILD_SERVICE_NAME`: (Optional) Defaults to `pottery-api`. Must match build step.
* `BUILD_REGION`: (Optional) Defaults to `us-central1`. Must match build step.
* `BUILD_REPO_NAME`: (Optional) Defaults to `pottery-app-repo`. Must match build step.
* `CLOUD_RUN_SERVICE_ACCOUNT_EMAIL`: (Optional) Email for the runtime service account. Defaults provided.
* `DEPLOYMENT_SERVICE_ACCOUNT_EMAIL`: **(Required)** Email of the deployer service account.
* `DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE`: **(Required)** Path to the deployer service account key file.
* Other runtime variables from `.env` can also be included in the `ENV_VARS` construction within the script if needed.

**Run the Deploy Script:**

```bash
chmod +x deploy.sh
./deploy.sh
```
The script will:
1. Authenticate using the deployment service account key.
2. **Check if the specified Artifact Registry repository exists and create it if it doesn't (requires `roles/artifactregistry.admin` for the deployer SA).**
3. Deploy the pre-built image to Cloud Run using the specified configuration.

After deployment, Cloud Run will provide a service URL where your API will be accessible.
