# main.py
import logging
from contextlib import asynccontextmanager
from datetime import datetime, timedelta

import jwt
import uvicorn
from fastapi import Depends, FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import OAuth2PasswordRequestForm
from google.cloud.exceptions import GoogleCloudError

from auth import initialize_auth

# Import settings first to ensure it's initialized
from config import settings

# Models imported as needed for type hinting in exception handlers
from routers import account, items, photos

# --- Logging Configuration ---
# Configure logging (adjust level and format as needed)
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


# --- Lifespan Management (Replaces startup/shutdown events) ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Context manager to handle application startup and shutdown logic.
    """
    # --- Startup Logic ---
    logger.info("Application starting up...")

    # Initialize Firebase authentication
    try:
        initialize_auth()
        logger.info("Firebase authentication initialized successfully.")
    except Exception as e:
        # This looks odd, but it saves us from startup failures in dev
        # Firebase will be initialized on first token verification attempt
        logger.warning(f"Firebase authentication initialization deferred: {e}")

    # Services now use lazy initialization - clients will be created on first use
    # This allows the application to start even without Google Cloud credentials
    logger.info("Backend services configured for lazy initialization.")
    logger.info("Application startup complete.")

    yield  # Application runs while yielded

    # --- Shutdown Logic ---
    logger.info("Application shutting down...")
    # Add any explicit cleanup logic here if needed (e.g., closing connections)
    # For google-cloud libraries, explicit closing is often not required
    # as clients manage connections.
    logger.info("Application shutdown complete.")


# --- Dynamically Create Servers List ---
# *** FIX: Create servers list dynamically using initialized settings.port ***
servers_list = [
    # Replace this placeholder with your actual Cloud Run URL when known
    {
        "url": "https://pottery-api-1073709451179.us-central1.run.app",
        "description": "Cloud Run Service (Replace)",
    },
    # Use the correctly initialized settings.port value here
    {
        "url": f"http://localhost:{settings.port}",
        "description": "Local Development Server",
    },
]
# Note: You could potentially add logic here to dynamically determine the
# Cloud Run URL if running in that environment, using settings.service_name etc.,
# but the placeholder is simpler.

# --- FastAPI Application Initialization ---
app = FastAPI(
    title=settings.api_title,
    description=settings.api_description,
    version=settings.api_version,
    openapi_url="/api/v1/openapi.json",  # Standard location for OpenAPI spec
    docs_url="/api/docs",  # Swagger UI
    redoc_url="/api/redoc",  # ReDoc UI
    servers=servers_list,  # *** FIX: Pass the dynamically created list ***
    lifespan=lifespan,
)

# Add CORS middleware to allow cross-origin requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)


# --- Global Exception Handlers ---
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """Custom handler for FastAPI's HTTPException."""
    logger.warning(
        f"HTTPException caught: Status={exc.status_code}, " f"Detail={exc.detail}"
    )
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail},
        headers=getattr(exc, "headers", None),
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handler for Pydantic validation errors."""
    logger.warning(f"Request validation error: {exc.errors()}")
    # Convert Pydantic errors to the format defined in OpenAPI schema
    error_details = []
    for error in exc.errors():
        error_details.append(
            {
                "loc": list(error["loc"]),
                "msg": error["msg"],
                "type": error["type"],
            }
        )
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": error_details},  # Matches HTTPValidationError schema
    )


@app.exception_handler(GoogleCloudError)
async def google_cloud_exception_handler(request: Request, exc: GoogleCloudError):
    """Handler for generic Google Cloud errors."""
    logger.error(f"Google Cloud Error: {exc}", exc_info=True)
    # Determine appropriate status code
    # (e.g., 503 for connectivity, 500 for others)
    status_code = (
        status.HTTP_503_SERVICE_UNAVAILABLE
        if "unavailable" in str(exc).lower()
        else status.HTTP_500_INTERNAL_SERVER_ERROR
    )
    return JSONResponse(
        status_code=status_code,
        content={"detail": f"A Google Cloud service error occurred: {exc}"},
    )


@app.exception_handler(ConnectionError)
async def connection_error_handler(request: Request, exc: ConnectionError):
    """Handler specifically for ConnectionErrors raised by services."""
    logger.error(f"Service Connection Error: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        content={"detail": "A required backend service is currently unavailable."},
    )


@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    """Catch-all handler for unexpected errors."""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "An unexpected internal server error occurred."},
    )


# --- API Routers ---
app.include_router(items.router)
app.include_router(photos.router)
app.include_router(account.router)


# --- Temporary Test Authentication Endpoint (for demo only) ---
@app.post(
    "/api/test-token", tags=["Testing"], summary="Generate Test Token (Demo Only)"
)
async def create_test_token(form_data: OAuth2PasswordRequestForm = Depends()):
    """Generate a test JWT token for demo purposes."""
    # Simple test credentials
    if form_data.username == "test" and form_data.password == "test":
        # Create test JWT token that mimics Firebase format
        payload = {
            "sub": "test_user_123",  # Firebase UID equivalent
            "email": "test@example.com",
            "name": "Test User",
            "exp": datetime.utcnow() + timedelta(hours=24),
            "iss": "pottery-test",
        }
        token = jwt.encode(payload, settings.jwt_secret_key, algorithm="HS256")
        return {"access_token": token, "token_type": "bearer"}
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials. Use username: test, password: test",
        )


# --- Root Endpoint ---
@app.get("/", tags=["Health Check"], summary="Health Check")
async def read_root():
    """Basic health check endpoint."""
    logger.info("Health check endpoint '/' accessed.")
    return {"message": f"Welcome to the {settings.api_title}!"}


# --- Version Endpoint ---
@app.get("/api/version", tags=["Version"], summary="Get API Version")
async def get_version():
    """
    Returns backend version and minimum required frontend version.

    Frontend apps should check this endpoint on startup to ensure compatibility.
    If the frontend version is older than min_frontend_version, the app should
    prompt the user to update from Google Play Store.
    """
    logger.info("Version check endpoint '/api/version' accessed.")
    return {
        "backend_version": settings.api_version,
        "min_frontend_version": settings.min_frontend_version,
    }


# --- Main Execution Block (for local development) ---
if __name__ == "__main__":
    # Ensure port is accessed *after* settings is initialized
    logger.info(
        f"Starting Uvicorn server locally on host 0.0.0.0, " f"port {settings.port}..."
    )
    uvicorn.run(
        "main:app",  # Points to the FastAPI app instance
        host="0.0.0.0",  # Listen on all available network interfaces
        port=settings.port,  # Use the initialized port
        reload=True,  # Enable auto-reload for dev (requires 'watchfiles')
        log_level="info",  # Uvicorn's log level
    )
