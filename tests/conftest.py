# tests/conftest.py
import pytest
from fastapi.testclient import TestClient
import sys
import os
from unittest.mock import AsyncMock # Import AsyncMock for async functions

# Add project root to path to allow importing 'main' and other modules
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)

# Ensure settings are loaded for testing (can use test-specific .env if needed)
# This import implicitly loads settings from .env or environment
# Important: Ensure .env exists or required env vars are set for config loading
try:
    from config import settings
except ImportError as e:
    print(f"Error importing config: {e}. Make sure config.py exists and project root is in sys.path.")
    # Provide default values or raise error if settings are crucial for app setup
    # For testing where services are mocked, exact config values might be less critical
    # but the FastAPI app initialization still needs the 'settings' object.
    # As a fallback for tests if config fails:
    # settings = type('obj', (object,), {'api_title': 'Test API', 'port': 8000})()
    pass


# Import the FastAPI app instance
# This should happen AFTER potentially setting test environment variables
# or modifying sys.path if your config depends on relative paths.
try:
    from main import app as fastapi_app
except ImportError as e:
     print(f"Error importing main: {e}. Make sure main.py exists and project root is in sys.path.")
     # Cannot proceed without the app instance
     pytest.exit(f"Failed to import FastAPI app from main.py: {e}", 1)


@pytest.fixture(scope="session")
def client() -> TestClient:
    """
    Create a FastAPI TestClient instance for the session.
    """
    # If you need to override dependencies for *all* tests, do it here using app.dependency_overrides
    # Example:
    # def get_mock_firestore(): return AsyncMock()
    # fastapi_app.dependency_overrides[firestore_service.get_db] = get_mock_firestore
    # We will use pytest-mock per-test instead for more granular control.
    with TestClient(fastapi_app) as test_client:
        yield test_client

# Optional: Fixture for base API URL prefix if needed elsewhere
@pytest.fixture(scope="session")
def api_prefix() -> str:
    # Adjust if your routers use a different global prefix in main.py
    return "" # Assuming routers are included directly under root

# Optional: Fixture for common headers
@pytest.fixture(scope="session")
def common_headers() -> dict:
    return {"Content-Type": "application/json"}

