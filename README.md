# Pottery Catalog API

## Overview

This project provides a RESTful API for managing a catalog of pottery items. It uses FastAPI as the web framework, Google Firestore for storing item metadata, and Google Cloud Storage (GCS) for storing associated photos. Access to photos is provided via temporary signed URLs generated on demand.

The application is designed to be containerized using Docker and deployed to Google Cloud Run.

## Features

* **CRUD Operations for Items:** Create, Read, Update, and Delete pottery item metadata (name, clay type, location, notes, measurements, created date/time).
* **Photo Management:** Upload photos associated with specific items, update photo metadata (stage, notes), and delete photos.
* **Secure Photo Access:** Photos are stored privately in GCS, and access is granted via short-lived Signed URLs included in API responses.
* **JWT Authentication:** Secure API access using JWT tokens with username/password authentication.
* **Timezone Awareness:** Stores creation/upload timestamps in UTC while preserving the original client timezone information.
* **Automatic API Documentation:** Interactive documentation (Swagger UI and ReDoc) generated automatically by FastAPI.
* **Containerized Deployment:** Includes a Dockerfile ready for building and deploying on Google Cloud Run or other container platforms.

## Technology Stack

* **Backend Framework:** FastAPI
* **Database:** Google Cloud Firestore (Native Mode)
* **Storage:** Google Cloud Storage (GCS)
* **Containerization:** Docker
* **Configuration:** Pydantic Settings (via Environment Variables)
* **Testing:** Pytest, pytest-asyncio, pytest-mock

## Project Structure

```
.
├── .env.local            # Environment variables for LOCAL docker run (add to .gitignore!)
├── .env.local.example    # Example for local run
├── .env.deploy           # Environment variables for BUILD/DEPLOY (add to .gitignore!)
├── .env.deploy.example   # Example for build/deploy
├── .env.test             # Environment variables for TESTING (add to .gitignore!)
├── .env.test.example     # Example for testing
├── Dockerfile            # Container definition
├── requirements.txt      # Python dependencies
├── requirements-dev.txt  # Development/test dependencies
├── config.py             # Application settings/configuration
├── main.py               # FastAPI app entry point and global handlers
├── models.py             # Pydantic data models (incl. internal and response models)
├── auth.py               # JWT authentication functionality
├── pytest.ini            # Pytest configuration (e.g., markers)
├── README.md             # This file
├── build_and_deploy.sh   # Script to build & deploy image to Cloud Run
├── run_docker_local.sh   # Script to build & run Docker container locally
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
    ├── test_auth.py        # Unit tests for authentication
    ├── images/             # Directory for test images
    │   ├── crackle.jpeg    # Example test image
    │   ├── arthur.jpeg     # Additional test image
    │   ├── Cardboard Angel Merged_01_00_56_22.jpg # Additional test image
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
* Docker installed and running.
* Access to a Google Cloud Project with Firestore (Native Mode) and Cloud Storage enabled.

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd <repository-directory>
```

### 2. Set Up Environment Variables

This project uses separate `.env` files for different environments:

* **`.env.local` (For Local Docker Run):**
    * Copy `.env.local.example` to `.env.local`.
    * Edit `.env.local` and fill in:
        * `GCP_PROJECT_ID`: Your project ID. **(Required)**
        * `GCS_BUCKET_NAME`: Your GCS bucket name. **(Required)**
        * `HOST_KEY_PATH`: **Absolute path** on your computer to a service account key file with Firestore/GCS permissions. This key is used for authentication when running locally. **(Required)**
        * `JWT_SECRET_KEY`: Secret key for JWT token signing. Generate a secure random key for production. **(Recommended)**
        * (Optional) `FIRESTORE_COLLECTION`, `FIRESTORE_DATABASE_ID`, `PORT`, `LOCAL_PORT`, `SIGNED_URL_EXPIRATION_MINUTES`, `JWT_ALGORITHM`, `JWT_ACCESS_TOKEN_EXPIRE_MINUTES`. Defaults are provided in `config.py` or `run_docker_local.sh`.
* **`.env.deploy` (For Build & Deployment):**
    * Copy `.env.deploy.example` to `.env.deploy`.
    * Edit `.env.deploy` and fill in:
        * `GCP_PROJECT_ID`: Your project ID. **(Required)**
        * `GCS_BUCKET_NAME`: The GCS bucket name the *deployed Cloud Run service* will use. **(Required)**
        * `DEPLOYMENT_SERVICE_ACCOUNT_EMAIL`: Email of the service account used *to run the deployment script*. Needs broad permissions (Build, AR, Run, IAM). **(Required)**
        * `DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE`: **Absolute path** to the key file for the deployment service account. **(Required)**
        * (Optional) `FIRESTORE_COLLECTION`, `FIRESTORE_DATABASE_ID`, `SIGNED_URL_EXPIRATION_MINUTES` (Runtime config for Cloud Run).
        * (Optional) `BUILD_SERVICE_NAME`, `BUILD_REGION`, `BUILD_REPO_NAME` (Build/Deploy parameters, defaults exist).
        * (Optional) `CLOUD_RUN_SERVICE_ACCOUNT_EMAIL`: Email of the SA the Cloud Run service will *run as* (runtime identity). Needs Firestore/GCS permissions. Defaults provided.
* **`.env.test` (For Testing):**
    * Copy `.env.test.example` to `.env.test`.
    * Edit `.env.test` and fill in:
        * `GCP_PROJECT_ID`: Use your **TEST** project ID. **(Required)**
        * `GCS_BUCKET_NAME`: Use your **TEST** GCS bucket name. **(Required)**
        * (Optional) `JWT_SECRET_KEY`, `JWT_ALGORITHM`, `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` for authentication testing.
        * (Optional) `FIRESTORE_*`, `SIGNED_URL_EXPIRATION_MINUTES` for test environment.
        * **For Integration Tests:** You also need authentication. Either set `GOOGLE_APPLICATION_CREDENTIALS=/path/to/your/TEST-keyfile.json` within `.env.test` OR set this variable in your shell environment before running `pytest`.
* **Important:** Add `.env.local`, `.env.deploy`, and `.env.test` to your `.gitignore` file.

### 3. Install Dependencies

```bash
# Install application dependencies
pip install -r requirements.txt

# Install development/testing dependencies
pip install -r requirements-dev.txt
```

### 4. Run the Application Locally (via Docker)

This script builds the image and runs the container using configuration from `.env.local`.

```bash
chmod +x run_docker_local.sh
./run_docker_local.sh
```
The application will be accessible at `http://localhost:[LOCAL_PORT]` (default `http://localhost:8000`).

### 5. Debugging with PyCharm

You can use PyCharm's remote debugger to debug your application running in Docker. The project has already been configured to support this.

#### Step 1: Start the Docker Container in Debug Mode

Run the Docker container with debugging enabled:

```bash
./run_docker_local.sh --debug
```

This will:
- Build the Docker image with debugpy installed
- Start the container with port 5678 exposed for debugging
- Launch the application with debugpy in "wait-for-client" mode
- The application will pause at startup, waiting for the debugger to connect

#### Step 2: Configure PyCharm Remote Debugger

1. In PyCharm, go to **Run** → **Edit Configurations...**
2. Click the **+** button and select **Python Debug Server**
3. Configure the debug server:
   - **Name**: Give it a name like "Docker Debug"
   - **Host**: localhost
   - **Port**: 5678 (the debug port exposed in the Docker container)
   - **Path mappings**: Map your local project directory to `/app` in the container
     - For example: `/Users/samwachtel/PycharmProjects/potteryapp/pottery-backend` → `/app`
4. Click **OK** to save the configuration

#### Step 3: Start Debugging

1. Set breakpoints in your code where needed
2. Select your "Docker Debug" configuration from the dropdown in the top-right corner
3. Click the debug button (green bug icon) or press Shift+F9
4. PyCharm will connect to the waiting debugpy server in the Docker container
5. The application will start running and will pause at your breakpoints

#### Step 4: Debug Your Application

- Use PyCharm's debugging tools to inspect variables, step through code, etc.
- When you're done debugging, you can stop the debugger in PyCharm
- To stop the Docker container, press Ctrl+C in the terminal where you started it

#### Troubleshooting

- If the connection fails, make sure:
  - The Docker container is running in debug mode
  - Port 5678 is not being used by another application
  - Your path mappings are correct
- If breakpoints are not being hit, verify that:
  - The source files in PyCharm match those in the container
  - The breakpoints are set in code that actually gets executed
- If you see a warning about frozen modules, this has been fixed by adding the `-Xfrozen_modules=off` flag to the Python command in the `run_docker_local.sh` script. This flag disables frozen modules, which can cause the debugger to miss breakpoints.

#### Notes

- The debugpy server is configured to wait for a connection before starting the application
- You can modify the debug port in your `.env.local` file by setting the `DEBUG_PORT` variable

### 6. Access API Documentation (Local Docker)

Once the container is running, access the interactive API documentation (Swagger UI) in your browser:

* `http://localhost:LOCAL_PORT:8000/api/docs`

You can also view the ReDoc documentation at `/api/redoc`.

## API Endpoints Summary

The API provides endpoints for managing pottery items and their photos. Key endpoints include:

### Authentication
* `POST /api/token`: Obtain a JWT token using username and password.

For development and testing, the API comes with a default user:
* Username: `admin`
* Password: `admin`

**Note:** In production, you should change the default credentials and use a secure password.

#### How to Authenticate as Admin

1. **Obtain a JWT Token**:
   ```bash
   curl -X POST "http://localhost:8000/api/token" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "username=admin&password=admin"
   ```

   This will return a JSON response with an access token:
   ```json
   {
     "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
     "token_type": "bearer"
   }
   ```

2. **Use the Token in Subsequent Requests**:
   ```bash
   curl -X GET "http://localhost:8000/api/items" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
   ```

3. **Token Expiration**: By default, tokens expire after the time specified in your configuration (default: 30 minutes). After expiration, you'll need to obtain a new token.

### User Data Association

All data in the system (pottery items and photos) is associated with the authenticated user. This means:

* When you create items or upload photos, they are automatically associated with your user account
* You can only view, update, and delete your own items and photos
* Admin users can access all items (for administrative purposes)

### Items and Photos
* `GET /`: Health check.
* `GET /api/items`: List all pottery items belonging to the authenticated user.
* `POST /api/items`: Create a new pottery item associated with the authenticated user.
* `GET /api/items/{item_id}`: Get a specific item by ID (if it belongs to the authenticated user).
* `PUT /api/items/{item_id}`: Update an item's metadata (if it belongs to the authenticated user).
* `DELETE /api/items/{item_id}`: Delete an item and its photos (if it belongs to the authenticated user).
* `POST /api/items/{item_id}/photos`: Upload a photo for an item (if it belongs to the authenticated user).
* `PUT /api/items/{item_id}/photos/{photo_id}`: Update a photo's metadata (if the parent item belongs to the authenticated user).
* `DELETE /api/items/{item_id}/photos/{photo_id}`: Delete a specific photo (if the parent item belongs to the authenticated user).

All endpoints except the health check (`GET /`) and token endpoint (`POST /api/token`) require authentication using a JWT token in the Authorization header.

For detailed request/response schemas and to try out the API, please refer to the interactive documentation at `/api/docs`.

## Testing

### Test Environment Setup

* Create a `.env.test` file (copy from `.env.test.example`).
* Fill in `GCP_PROJECT_ID` and `GCS_BUCKET_NAME` with values for your **test environment**.
* For **integration tests**, ensure you have authenticated access to the test GCP project. Set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable either in `.env.test` or in your shell, pointing to a service account key file with permissions for the **test** project's Firestore and GCS resources.
* Create the `tests/images` directory and place a `crackle.jpeg` file inside it for integration tests.

### Unit Tests

These tests mock external services (Firestore, GCS) and verify the API logic in isolation. They rely on `GCP_PROJECT_ID` and `GCS_BUCKET_NAME` being set in `.env.test` (even dummy values work) but don't require `GOOGLE_APPLICATION_CREDENTIALS`.

```bash
# Run all tests except integration tests
pytest -m "not integration"
```
Or (if not using markers):
```bash
pytest --ignore=tests/integration
```

### Integration Tests

These tests interact with **real** Google Cloud services specified in `.env.test`. **Ensure you are configured to use a non-production test environment and have set `GOOGLE_APPLICATION_CREDENTIALS` correctly.**

```bash
# Run only integration tests
pytest -m integration
```
Or (if not using markers):
```bash
pytest tests/integration/
```

## Deployment to Google Cloud Run

Use the single script `build_and_deploy.sh` to build the image using Cloud Build and deploy it to Cloud Run.

### Prerequisites

* Google Cloud SDK (`gcloud`) configured.
* Required GCP APIs enabled (Cloud Run, Cloud Build, Artifact Registry, Firestore, Cloud Storage).
* An Artifact Registry repository created (or use GCR). **Note:** The script can now create this if it doesn't exist.
* A Service Account for the Cloud Run service (runtime identity) with appropriate IAM roles (e.g., `Firestore User`, `Storage Object Admin`).
* A separate Service Account for **running the deployment** with broader permissions (e.g., `Artifact Registry Administrator`, `Cloud Build Editor`, `Cloud Run Admin`, `Service Account User`) and a downloaded key file.

### Configure Deployment Variables

Ensure all necessary variables are set in `.env.deploy` (see Step 2 under Setup). Pay close attention to:
* `GCP_PROJECT_ID`
* `GCS_BUCKET_NAME` (for runtime)
* `DEPLOYMENT_SERVICE_ACCOUNT_EMAIL`
* `DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE`
* (Optional) `BUILD_*` variables
* (Optional) `CLOUD_RUN_SERVICE_ACCOUNT_EMAIL`
* (Optional) `JWT_SECRET_KEY`, `JWT_ALGORITHM`, `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` (Authentication config)
* (Optional) Runtime `FIRESTORE_*`, `SIGNED_URL_EXPIRATION_MINUTES`

### Run the Build and Deploy Script

```bash
chmod +x build_and_deploy.sh
./build_and_deploy.sh
```
The script will:
1. Authenticate using the deployment service account key.
2. Check/Create the Artifact Registry repository.
3. Trigger Cloud Build to build and push the Docker image.
4. Deploy the newly built image to Cloud Run using the specified configuration.

After successful execution, Cloud Run will provide a service URL where your API will be accessible.
