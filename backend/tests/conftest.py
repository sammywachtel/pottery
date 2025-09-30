# tests/conftest.py
import os
import sys
from unittest.mock import Mock, patch

import pytest

# *** ADDED: Import load_dotenv ***
from dotenv import load_dotenv
from fastapi.testclient import TestClient

# Mock imports removed as they're not used in this conftest


# *** ADDED: Load test environment variables very early ***
print("Attempting to load .env.test from tests/conftest.py...")
# Construct path relative to this conftest.py file (assuming it's in tests/)
# Go up one level to the project root, then find .env.test
dotenv_path = os.path.join(os.path.dirname(__file__), "..", ".env.test")
if os.path.exists(dotenv_path):
    # override=True ensures that env vars from .env.test take precedence
    # over any existing system environment variables.
    load_dotenv(dotenv_path=dotenv_path, override=True)
    print(f".env.test loaded successfully from: {dotenv_path}")
else:
    print(
        f"Warning: .env.test file not found at {dotenv_path}. "
        f"Relying on system environment variables."
    )
    # Optionally, check if required variables are present in the environment
    # anyway
    required_vars = [
        "GCP_PROJECT_ID",
        "GCS_BUCKET_NAME",
        "FIREBASE_PROJECT_ID",
        "FIREBASE_API_KEY",
        "FIREBASE_AUTH_DOMAIN",
    ]
    missing_vars = [v for v in required_vars if v not in os.environ]
    if missing_vars:
        print(
            f"ERROR: Required test environment variables missing: "
            f"{', '.join(missing_vars)}"
        )
        pytest.exit(
            f"Required test environment variables {', '.join(missing_vars)} "
            f"not set and .env.test not found.",
            1,
        )


# Add project root to path AFTER loading env vars, in case config depends on it
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

# Now import config and main, which will initialize Settings using loaded
# env vars
try:
    print("Importing config...")
    from config import settings

    print("Config imported successfully.")
    # Log critical settings to verify they loaded
    print(f"Loaded GCP_PROJECT_ID: {os.getenv('GCP_PROJECT_ID')}")
    print(f"Loaded GCS_BUCKET_NAME: {os.getenv('GCS_BUCKET_NAME')}")
except ImportError as e:
    print(
        f"Error importing config: {e}. Make sure config.py exists and "
        f"project root is in sys.path."
    )
    settings = None  # Set to None or fallback if needed
    pytest.exit(f"Failed to import config.py: {e}", 1)
except (
    Exception
) as e_settings:  # Catch potential validation errors during import  # noqa: E501
    print(f"Error initializing Settings from config.py: {e_settings}")
    pytest.exit(f"Failed to initialize Settings: {e_settings}", 1)


try:
    print("Importing main app...")
    from main import app as fastapi_app

    print("Main app imported successfully.")
except ImportError as e:
    print(
        f"Error importing main: {e}. Make sure main.py exists and "
        f"project root is in sys.path."
    )
    pytest.exit(f"Failed to import FastAPI app from main.py: {e}", 1)


@pytest.fixture(scope="session")
def client() -> TestClient:
    """
    Create a FastAPI TestClient instance for the session.
    """
    print("Creating TestClient...")
    try:
        with TestClient(fastapi_app) as test_client:
            print("TestClient created.")
            yield test_client
    except Exception as e:
        print(f"ERROR creating TestClient: {e}")
        pytest.fail(f"Failed to create TestClient: {e}")


# Optional: Fixture for base API URL prefix if needed elsewhere
@pytest.fixture(scope="session")
def api_prefix() -> str:
    return ""  # Assuming routers are included directly under root


# Optional: Fixture for common headers
@pytest.fixture(scope="session")
def common_headers() -> dict:
    return {"Content-Type": "application/json"}


# Authentication fixtures
@pytest.fixture
def auth_headers(mock_firebase_token) -> dict:
    """Get authentication headers with a valid Firebase token."""
    return {"Authorization": f"Bearer {mock_firebase_token}"}


@pytest.fixture
def mock_firebase_user():
    """Mock Firebase user data for testing."""
    return {
        "uid": "test-firebase-uid-123",
        "email": "test@example.com",
        "name": "Test User",
        "picture": "https://example.com/photo.jpg",
        "email_verified": True,
    }


@pytest.fixture
def mock_firebase_token():
    """Mock Firebase ID token for testing."""
    return "mock-firebase-id-token-for-testing"


@pytest.fixture
def firebase_auth_headers(mock_firebase_token):
    """Get authentication headers with a mocked Firebase token."""
    return {"Authorization": f"Bearer {mock_firebase_token}"}


@pytest.fixture(autouse=True)
def mock_firebase_auth(request, mock_firebase_user, mock_firebase_token):
    """Automatically mock Firebase authentication for all tests."""
    # Skip mocking for tests marked with no_firebase_mock
    if hasattr(request, "node") and request.node.get_closest_marker("no_firebase_mock"):
        yield None
        return

    with patch("auth.verify_firebase_token") as mock_verify:
        with patch("auth.extract_user_info") as mock_extract:
            with patch("auth.create_or_update_user_profile") as mock_profile:
                # Import settings here to avoid circular import issues
                from config import settings

                with patch.object(
                    type(settings),
                    "firebase_enabled",
                    new_callable=lambda: property(lambda self: True),
                ):
                    # Opening move: setup Firebase token verification
                    mock_verify.return_value = {"uid": mock_firebase_user["uid"]}
                    mock_extract.return_value = mock_firebase_user
                    mock_profile.return_value = {"isAdmin": True}

                    yield {
                        "verify_token": mock_verify,
                        "extract_user": mock_extract,
                        "create_profile": mock_profile,
                    }
