"""Unit tests for configuration settings."""

import os
import tempfile
from unittest.mock import patch

import pytest

from config import Settings

# Mark to disable the autouse firebase mock for config tests
pytestmark = pytest.mark.no_firebase_mock


class TestFirebaseEnabled:
    """Test the firebase_enabled property logic."""

    def test_firebase_disabled_no_project_id(self):
        """Test Firebase is disabled when no project ID is set."""
        with patch.dict(
            os.environ,
            {
                "GCP_PROJECT_ID": "test-project",
                "GCS_BUCKET_NAME": "test-bucket",
                # Note: No FIREBASE_PROJECT_ID set
            },
            clear=True,
        ):
            settings = Settings()
            assert not settings.firebase_enabled

    def test_firebase_disabled_project_id_only(self):
        """Test Firebase is disabled with only project ID (no credentials)."""
        with patch.dict(
            os.environ,
            {
                "FIREBASE_PROJECT_ID": "test-project",
                "GCP_PROJECT_ID": "test-project",
                "GCS_BUCKET_NAME": "test-bucket",
                # Note: No GOOGLE_APPLICATION_CREDENTIALS, GOOGLE_CLOUD_PROJECT, or GCP_PROJECT
            },
            clear=True,
        ):
            settings = Settings()
            assert not settings.firebase_enabled

    def test_firebase_enabled_with_service_account_file(self):
        """Test Firebase is enabled with project ID and service account file."""
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            f.write('{"type": "service_account"}')
            service_account_path = f.name

        try:
            with patch.dict(
                os.environ,
                {
                    "FIREBASE_PROJECT_ID": "test-project",
                    "FIREBASE_CREDENTIALS_FILE": service_account_path,
                    "GCP_PROJECT_ID": "test-project",
                    "GCS_BUCKET_NAME": "test-bucket",
                },
                clear=True,
            ):
                settings = Settings()
                assert settings.firebase_enabled
        finally:
            os.unlink(service_account_path)

    def test_firebase_disabled_with_nonexistent_service_account_file(self):
        """Test Firebase is disabled when service account file doesn't exist."""
        with patch.dict(
            os.environ,
            {
                "FIREBASE_PROJECT_ID": "test-project",
                "FIREBASE_CREDENTIALS_FILE": "/nonexistent/path/service-account.json",
                "GCP_PROJECT_ID": "test-project",
                "GCS_BUCKET_NAME": "test-bucket",
            },
            clear=True,
        ):
            settings = Settings()
            assert not settings.firebase_enabled

    def test_firebase_enabled_with_adc_env_var(self):
        """Test Firebase is enabled with ADC environment variable."""
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            f.write('{"type": "service_account"}')
            adc_path = f.name

        try:
            with patch.dict(
                os.environ,
                {
                    "FIREBASE_PROJECT_ID": "test-project",
                    "GOOGLE_APPLICATION_CREDENTIALS": adc_path,
                    "GCP_PROJECT_ID": "test-project",
                    "GCS_BUCKET_NAME": "test-bucket",
                },
                clear=True,
            ):
                settings = Settings()
                assert settings.firebase_enabled
        finally:
            os.unlink(adc_path)

    def test_firebase_enabled_with_google_cloud_project(self):
        """Test Firebase is enabled in Google Cloud environment."""
        with patch.dict(
            os.environ,
            {
                "FIREBASE_PROJECT_ID": "test-project",
                "GOOGLE_CLOUD_PROJECT": "test-project",
                "GCP_PROJECT_ID": "test-project",
                "GCS_BUCKET_NAME": "test-bucket",
            },
            clear=True,
        ):
            settings = Settings()
            assert settings.firebase_enabled

    def test_firebase_enabled_with_gcp_project(self):
        """Test Firebase is enabled with GCP_PROJECT environment variable."""
        with patch.dict(
            os.environ,
            {
                "FIREBASE_PROJECT_ID": "test-project",
                "GCP_PROJECT": "test-project",
                "GCP_PROJECT_ID": "test-project",
                "GCS_BUCKET_NAME": "test-bucket",
            },
            clear=True,
        ):
            settings = Settings()
            assert settings.firebase_enabled

    def test_firebase_enabled_precedence_service_account_over_adc(self):
        """Test that explicit service account file takes precedence."""
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            f.write('{"type": "service_account"}')
            service_account_path = f.name

        try:
            with patch.dict(
                os.environ,
                {
                    "FIREBASE_PROJECT_ID": "test-project",
                    "FIREBASE_CREDENTIALS_FILE": service_account_path,
                    "GOOGLE_APPLICATION_CREDENTIALS": "/some/other/path.json",
                    "GCP_PROJECT_ID": "test-project",
                    "GCS_BUCKET_NAME": "test-bucket",
                },
                clear=True,
            ):
                settings = Settings()
                assert settings.firebase_enabled
        finally:
            os.unlink(service_account_path)

    def test_firebase_frontend_settings_ignored(self):
        """Test that frontend-only settings don't affect backend Firebase enablement."""
        with patch.dict(
            os.environ,
            {
                "FIREBASE_PROJECT_ID": "test-project",
                "FIREBASE_API_KEY": "some-api-key",
                "FIREBASE_AUTH_DOMAIN": "test-project.firebaseapp.com",
                "GOOGLE_CLOUD_PROJECT": "test-project",
                "GCP_PROJECT_ID": "test-project",
                "GCS_BUCKET_NAME": "test-bucket",
            },
            clear=True,
        ):
            settings = Settings()
            # Should be enabled due to GOOGLE_CLOUD_PROJECT, not because of API_KEY/AUTH_DOMAIN
            assert settings.firebase_enabled
            assert settings.firebase_api_key == "some-api-key"
            assert settings.firebase_auth_domain == "test-project.firebaseapp.com"

    def test_firebase_enabled_error_handling(self):
        """Test that exceptions in firebase_enabled don't crash the application."""
        with patch.dict(
            os.environ,
            {
                "FIREBASE_PROJECT_ID": "test-project",
                "GCP_PROJECT_ID": "test-project",
                "GCS_BUCKET_NAME": "test-bucket",
                # Note: Explicitly avoid setting env vars that would enable Firebase
            },
            clear=True,
        ):
            # Mock os.environ.get to raise an exception when checking for ADC
            with patch("os.environ.get", side_effect=Exception("Mocked error")):
                settings = Settings()
                # Should return False if there's an error checking ADC
                assert not settings.firebase_enabled


class TestSettingsValidation:
    """Test general settings validation."""

    def test_required_fields_present(self):
        """Test that required GCP fields are validated."""
        with pytest.raises(Exception):  # Should raise validation error
            with patch.dict(os.environ, {}, clear=True):
                Settings()

    def test_optional_firebase_fields(self):
        """Test that Firebase fields are optional."""
        with patch.dict(
            os.environ,
            {"GCP_PROJECT_ID": "test-project", "GCS_BUCKET_NAME": "test-bucket"},
            clear=True,
        ):
            settings = Settings()
            assert settings.firebase_project_id is None
            assert settings.firebase_credentials_file is None
            assert settings.firebase_api_key is None
            assert settings.firebase_auth_domain is None

    def test_default_values(self):
        """Test default values for optional settings."""
        with patch.dict(
            os.environ,
            {"GCP_PROJECT_ID": "test-project", "GCS_BUCKET_NAME": "test-bucket"},
            clear=True,
        ):
            settings = Settings()
            assert settings.firestore_collection == "pottery_items"
            assert settings.firestore_database_id == "(default)"
            assert settings.signed_url_expiration_minutes == 15
            assert settings.port == 8080
