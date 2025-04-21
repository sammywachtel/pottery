# config.py
import os
from pydantic_settings import BaseSettings
from pydantic import Field, AnyHttpUrl
from typing import Optional

# Load .env file if it exists (especially for local development)
from dotenv import load_dotenv
load_dotenv()

class Settings(BaseSettings):
    """
    Application configuration settings loaded from environment variables.
    """
    # --- Google Cloud Configuration ---
    gcp_project_id: str = Field(..., env="GCP_PROJECT_ID")
    gcs_bucket_name: str = Field(..., env="GCS_BUCKET_NAME")
    firestore_collection: str = Field("pottery_items", env="FIRESTORE_COLLECTION")
    # Defaults to "(default)" if not set in environment
    firestore_database_id: str = Field("(default)", env="FIRESTORE_DATABASE_ID")
    # --- Signed URL Configuration ---
    signed_url_expiration_minutes: int = Field(15, env="SIGNED_URL_EXPIRATION_MINUTES")

    # --- Cloud Run Environment (Optional but common) ---
    # Cloud Run injects PORT, K_SERVICE, K_REVISION
    port: int = Field(int(os.environ.get("PORT", 8080)), env="PORT") # Default to 8080 if not set
    service_name: Optional[str] = Field(os.environ.get("K_SERVICE"), env="K_SERVICE")
    service_revision: Optional[str] = Field(os.environ.get("K_REVISION"), env="K_REVISION")

    # --- API Information (from OpenAPI spec) ---
    api_title: str = "Pottery Catalog API (Signed URLs)"
    api_version: str = "0.2.0"
    api_description: str = "API for managing pottery items with Firestore and GCS, using signed URLs for photo access."

    # --- REMOVED servers list from here ---
    # servers: list[dict[str, str]] = [ ... ] # Removed

    class Config:
        # Load environment variables from a .env file if present
        env_file = '.env'
        env_file_encoding = 'utf-8'
        # Make Pydantic case-insensitive for environment variables
        case_sensitive = False

# Create a single instance of the settings to be imported elsewhere
settings = Settings()

# Example usage (optional, for testing):
if __name__ == "__main__":
    print("Configuration loaded:")
    print(f"GCP Project ID: {settings.gcp_project_id}")
    print(f"GCS Bucket Name: {settings.gcs_bucket_name}")
    print(f"Firestore Collection: {settings.firestore_collection}")
    print(f"Signed URL Expiration (minutes): {settings.signed_url_expiration_minutes}")
    print(f"Port: {settings.port}")
    # Note: servers list is no longer part of Settings object directly
