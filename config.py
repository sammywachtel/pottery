# config.py
import os
from pydantic_settings import BaseSettings, SettingsConfigDict # Import SettingsConfigDict
from pydantic import Field, AnyHttpUrl
from typing import Optional

# *** REMOVED: dotenv loading is no longer needed here ***
# from dotenv import load_dotenv
# load_dotenv()

class Settings(BaseSettings):
    """
    Application configuration settings loaded ONLY from environment variables.
    """
    # --- Google Cloud Configuration ---
    gcp_project_id: str = Field(..., validation_alias='GCP_PROJECT_ID')
    gcs_bucket_name: str = Field(..., validation_alias='GCS_BUCKET_NAME')
    firestore_collection: str = Field("pottery_items", validation_alias='FIRESTORE_COLLECTION')
    firestore_database_id: str = Field("(default)", validation_alias='FIRESTORE_DATABASE_ID')

    # --- Signed URL Configuration ---
    signed_url_expiration_minutes: int = Field(15, validation_alias='SIGNED_URL_EXPIRATION_MINUTES')

    # --- Cloud Run / Server Configuration ---
    # Read the PORT environment variable (set by Cloud Run or Docker -p)
    # Default to 8080 if not set, which is standard for Cloud Run.
    port: int = Field(default=8080, validation_alias='PORT')

    # Optional Cloud Run injected variables (useful for context/logging)
    service_name: Optional[str] = Field(None, validation_alias='K_SERVICE')
    service_revision: Optional[str] = Field(None, validation_alias='K_REVISION')

    # --- API Information (from OpenAPI spec) ---
    api_title: str = "Pottery Catalog API (Signed URLs)"
    api_version: str = "0.2.0"
    api_description: str = "API for managing pottery items with Firestore and GCS, using signed URLs for photo access."

    # Configure Pydantic settings
    model_config = SettingsConfigDict(
        # Make Pydantic case-insensitive for environment variables
        case_sensitive=False,
        # *** REMOVED: env_file configuration ***
        # env_file = '.env',
        # env_file_encoding = 'utf-8',
        # Allow aliases for environment variables (e.g., read GCP_PROJECT_ID into gcp_project_id)
        populate_by_name=True,
        extra='ignore' # Ignore extra environment variables not defined in the model
    )

# Create a single instance of the settings to be imported elsewhere
settings = Settings()

# Example usage (optional, for testing):
if __name__ == "__main__":
    print("Configuration loaded from environment:")
    print(f"GCP Project ID: {settings.gcp_project_id}")
    print(f"GCS Bucket Name: {settings.gcs_bucket_name}")
    print(f"Firestore Collection: {settings.firestore_collection}")
    print(f"Firestore Database ID: {settings.firestore_database_id}")
    print(f"Signed URL Expiration (minutes): {settings.signed_url_expiration_minutes}")
    print(f"Port: {settings.port}")
    print(f"K_SERVICE: {settings.service_name}")
    print(f"K_REVISION: {settings.service_revision}")

