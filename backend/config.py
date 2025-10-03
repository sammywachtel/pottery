# config.py
from typing import Optional

from pydantic import Field
from pydantic_settings import (  # Import SettingsConfigDict
    BaseSettings,
    SettingsConfigDict,
)

# *** REMOVED: dotenv loading is no longer needed here ***
# from dotenv import load_dotenv
# load_dotenv()


class Settings(BaseSettings):
    """
    Application configuration settings loaded ONLY from environment variables.
    """

    # --- Environment Configuration ---
    environment: str = Field("development", validation_alias="ENVIRONMENT")

    # --- Google Cloud Configuration ---
    gcp_project_id: str = Field(..., validation_alias="GCP_PROJECT_ID")
    gcs_bucket_name: str = Field(..., validation_alias="GCS_BUCKET_NAME")
    firestore_collection: str = Field(
        "pottery_items", validation_alias="FIRESTORE_COLLECTION"
    )
    firestore_database_id: str = Field(
        "(default)", validation_alias="FIRESTORE_DATABASE_ID"
    )

    # --- Signed URL Configuration ---
    signed_url_expiration_minutes: int = Field(
        15, validation_alias="SIGNED_URL_EXPIRATION_MINUTES"
    )

    # --- Firebase Authentication Configuration ---
    firebase_project_id: Optional[str] = Field(
        None, validation_alias="FIREBASE_PROJECT_ID"
    )
    firebase_credentials_file: Optional[str] = Field(
        None, validation_alias="FIREBASE_CREDENTIALS_FILE"
    )
    # Frontend-only settings (not used by backend)
    firebase_api_key: Optional[str] = Field(None, validation_alias="FIREBASE_API_KEY")
    firebase_auth_domain: Optional[str] = Field(
        None, validation_alias="FIREBASE_AUTH_DOMAIN"
    )

    # --- JWT Configuration (LEGACY - for backward compatibility only) ---
    # TODO: Remove JWT_SECRET_KEY - not used with Firebase Auth
    # Only kept for legacy compatibility
    jwt_secret_key: Optional[str] = Field(None, validation_alias="JWT_SECRET_KEY")

    @property
    def is_development(self) -> bool:
        """Check if running in development environment."""
        return self.environment.lower() in ("development", "dev")

    @property
    def is_production(self) -> bool:
        """Check if running in production environment."""
        return self.environment.lower() in ("production", "prod")

    @property
    def debug_enabled(self) -> bool:
        """Check if debug mode should be enabled."""
        return self.is_development

    @property
    def firebase_enabled(self) -> bool:
        """Check if Firebase configuration is complete for backend use.

        Firebase is enabled when:
        1. FIREBASE_PROJECT_ID is set
        2. Credentials are available (service account file or ADC)

        Note: FIREBASE_API_KEY and FIREBASE_AUTH_DOMAIN are frontend-only settings.
        """
        import os

        # Opening move: check if project ID is set
        if not self.firebase_project_id:
            return False

        # Main play: check if credentials are available
        # Either via explicit service account file or ADC (default credentials)
        if self.firebase_credentials_file and os.path.exists(
            self.firebase_credentials_file
        ):
            return True

        # Victory lap: check for ADC (Google Cloud SDK or service account)
        # Automatically available in Cloud Run or when gcloud is configured
        try:
            # Check for Application Default Credentials environment variable
            if os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
                return True
            # Or if running in Google Cloud environment (Cloud Run, etc.)
            # Cloud Run sets K_SERVICE environment variable
            if (
                os.environ.get("GOOGLE_CLOUD_PROJECT")
                or os.environ.get("GCP_PROJECT")
                or os.environ.get("K_SERVICE")
            ):  # Cloud Run indicator
                return True
        except Exception:
            pass

        return False

    # --- Cloud Run / Server Configuration ---
    # Read the PORT environment variable (set by Cloud Run or Docker -p)
    # Default to 8080 if not set, which is standard for Cloud Run.
    port: int = Field(default=8080, validation_alias="PORT")

    # Optional Cloud Run injected variables (useful for context/logging)
    service_name: Optional[str] = Field(None, validation_alias="K_SERVICE")
    service_revision: Optional[str] = Field(None, validation_alias="K_REVISION")

    # --- API Information (from OpenAPI spec) ---
    api_title: str = "Pottery Catalog API (Signed URLs)"
    api_version: str = "0.2.0"
    api_description: str = (
        "API for managing pottery items with Firestore and GCS, "
        "using signed URLs for photo access."
    )

    # Configure Pydantic settings
    model_config = SettingsConfigDict(
        # Make Pydantic case-insensitive for environment variables
        case_sensitive=False,
        # *** REMOVED: env_file configuration ***
        # env_file = '.env',
        # env_file_encoding = 'utf-8',
        # Allow aliases for environment variables (e.g., read GCP_PROJECT_ID into gcp_project_id)  # noqa: E501
        populate_by_name=True,
        extra="ignore",  # Ignore extra environment variables not defined
    )


# Create a single instance of the settings to be imported elsewhere
settings = Settings()

# Example usage (optional, for testing):
if __name__ == "__main__":
    print("Configuration loaded from environment:")
    print(f"Environment: {settings.environment}")
    print(f"Is Development: {settings.is_development}")
    print(f"Is Production: {settings.is_production}")
    print(f"Debug Enabled: {settings.debug_enabled}")
    print(f"GCP Project ID: {settings.gcp_project_id}")
    print(f"GCS Bucket Name: {settings.gcs_bucket_name}")
    print(f"Firestore Collection: {settings.firestore_collection}")
    print(f"Firestore Database ID: {settings.firestore_database_id}")
    print(f"Signed URL Expiration (minutes): {settings.signed_url_expiration_minutes}")
    print(f"Port: {settings.port}")
    print(f"K_SERVICE: {settings.service_name}")
    print(f"K_REVISION: {settings.service_revision}")
