# tests/test_main.py
from fastapi import status
from fastapi.testclient import TestClient

# Import settings carefully, ensuring it's initialized
try:
    from config import settings
except ImportError:
    # Fallback if config import fails in test environment
    settings = type(
        "obj", (object,), {"api_title": "Pottery Catalog API (Signed URLs)"}
    )()


def test_read_root(client: TestClient):
    """Test the health check endpoint."""
    response = client.get("/")
    assert response.status_code == status.HTTP_200_OK
    # Use the imported or fallback settings title
    assert response.json() == {"message": f"Welcome to the {settings.api_title}!"}


# You can add tests for exception handlers here if needed,
# though they are often tested indirectly via router tests.
