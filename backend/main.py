# main.py
import logging
from contextlib import asynccontextmanager
from datetime import timedelta

import uvicorn
from fastapi import Depends, FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import OAuth2PasswordRequestForm
from google.cloud.exceptions import GoogleCloudError

from auth import (
    ACCESS_TOKEN_EXPIRE_MINUTES,
    Token,
    authenticate_user,
    create_access_token,
)

# Import settings first to ensure it's initialized
from config import settings

# Models imported as needed for type hinting in exception handlers
from routers import items, photos
from services import firestore_service, gcs_service

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
    # Check if Firestore/GCS clients initialized correctly during import
    # Note: The clients are initialized when the service modules are imported.
    if not firestore_service.db or not gcs_service.bucket:
        logger.critical(
            "FATAL: Firestore or GCS client failed to initialize during "
            "module import. Application may not function correctly."
        )
        # Optionally raise an error to prevent startup if critical
        # raise RuntimeError("Failed to initialize backend services.")
    else:
        logger.info("Firestore and GCS clients appear to be initialized.")
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


# --- Authentication Endpoint ---
@app.post("/api/token", response_model=Token, tags=["Authentication"], summary="Login")
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    """
    OAuth2 compatible token login, get an access token for future requests.
    """
    user = authenticate_user(form_data.username, form_data.password)
    if not user:
        logger.warning(f"Failed login attempt for user: {form_data.username}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )

    logger.info(f"Successful login for user: {form_data.username}")
    return {"access_token": access_token, "token_type": "bearer"}


# --- Root Endpoint ---
@app.get("/", tags=["Health Check"], summary="Health Check")
async def read_root():
    """Basic health check endpoint."""
    logger.info("Health check endpoint '/' accessed.")
    return {"message": f"Welcome to the {settings.api_title}!"}


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
