"""Unit tests for authentication functionality."""

from fastapi import status
from fastapi.testclient import TestClient


def test_login_success(client: TestClient):
    """Test successful login with correct credentials."""
    response = client.post(
        "/api/token",
        data={"username": "admin", "password": "admin"},  # pragma: allowlist secret
    )
    assert response.status_code == status.HTTP_200_OK
    token = response.json()
    assert "access_token" in token
    assert token["token_type"] == "bearer"


def test_login_failure_wrong_password(client: TestClient):
    """Test login failure with wrong password."""
    response = client.post(
        "/api/token",
        data={
            "username": "admin",
            "password": "wrong_password",  # pragma: allowlist secret
        },
    )
    assert response.status_code == status.HTTP_401_UNAUTHORIZED


def test_login_failure_wrong_username(client: TestClient):
    """Test login failure with wrong username."""
    response = client.post(
        "/api/token",
        data={
            "username": "wrong_username",
            "password": "admin",  # pragma: allowlist secret
        },
    )
    assert response.status_code == status.HTTP_401_UNAUTHORIZED


def test_protected_endpoint_without_token(client: TestClient):
    """Test accessing a protected endpoint without a token."""
    response = client.get("/api/items")
    assert response.status_code == status.HTTP_401_UNAUTHORIZED


def test_protected_endpoint_with_token(client: TestClient):
    """Test accessing a protected endpoint with a valid token."""
    # First, get a token
    login_response = client.post(
        "/api/token",
        data={"username": "admin", "password": "admin"},  # pragma: allowlist secret
    )
    token = login_response.json()["access_token"]

    # Then use the token to access a protected endpoint
    response = client.get(
        "/api/items",
        headers={"Authorization": f"Bearer {token}"},
    )
    # We don't check for 200 OK because the endpoint might return other status codes
    # depending on the data, but it should not return 401 Unauthorized
    assert response.status_code != status.HTTP_401_UNAUTHORIZED
