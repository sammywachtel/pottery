"""Test utilities and mocks for Firebase authentication testing.

This module provides:
- Mock Firebase tokens and decoded payloads
- Test fixtures for Firebase authentication scenarios
- Utilities for mocking Firebase Admin SDK functions
"""

from datetime import datetime, timedelta
from typing import Dict, Optional
from unittest.mock import Mock

import pytest
from firebase_admin import auth


class MockFirebaseToken:
    """Mock Firebase ID token for testing."""

    def __init__(
        self,
        uid: str = "test_user_123",
        email: str = "test@example.com",
        name: Optional[str] = "Test User",
        picture: Optional[str] = None,
        email_verified: bool = True,
        exp: Optional[datetime] = None,
        iat: Optional[datetime] = None,
    ):
        self.uid = uid
        self.email = email
        self.name = name
        self.picture = picture
        self.email_verified = email_verified
        self.exp = exp or datetime.utcnow() + timedelta(hours=1)
        self.iat = iat or datetime.utcnow()

    def to_dict(self) -> Dict[str, any]:
        """Convert to dictionary format matching Firebase token payload."""
        token_data = {
            "uid": self.uid,
            "email": self.email,
            "email_verified": self.email_verified,
            "exp": int(self.exp.timestamp()),
            "iat": int(self.iat.timestamp()),
        }

        if self.name:
            token_data["name"] = self.name

        if self.picture:
            token_data["picture"] = self.picture

        return token_data


class MockUserRecord:
    """Mock Firebase UserRecord for testing."""

    def __init__(
        self,
        uid: str = "test_user_123",
        email: str = "test@example.com",
        display_name: Optional[str] = "Test User",
        photo_url: Optional[str] = None,
        email_verified: bool = True,
        disabled: bool = False,
    ):
        self.uid = uid
        self.email = email
        self.display_name = display_name
        self.photo_url = photo_url
        self.email_verified = email_verified
        self.disabled = disabled


# Test data fixtures
VALID_FIREBASE_TOKEN = MockFirebaseToken()
ADMIN_FIREBASE_TOKEN = MockFirebaseToken(
    uid="admin_user_456", email="admin@potteryapp.test", name="Admin User"
)
EXPIRED_FIREBASE_TOKEN = MockFirebaseToken(exp=datetime.utcnow() - timedelta(hours=1))


def create_mock_firebase_auth():
    """Create a mock Firebase auth module for testing."""
    mock_auth = Mock()

    # Configure verify_id_token method
    def mock_verify_id_token(token: str) -> Dict[str, any]:
        """Mock Firebase token verification."""
        if token == "valid_token":
            return VALID_FIREBASE_TOKEN.to_dict()
        elif token == "admin_token":
            return ADMIN_FIREBASE_TOKEN.to_dict()
        elif token == "expired_token":
            raise auth.ExpiredIdTokenError("Token has expired")
        elif token == "invalid_token":
            raise auth.InvalidIdTokenError("Invalid token format")
        elif token == "revoked_token":
            raise auth.RevokedIdTokenError("Token has been revoked")
        else:
            raise auth.InvalidIdTokenError("Unknown token")

    mock_auth.verify_id_token = mock_verify_id_token

    # Configure get_user_by_email method
    def mock_get_user_by_email(email: str) -> MockUserRecord:
        """Mock Firebase get user by email."""
        if email == "test@example.com":
            return MockUserRecord()
        elif email == "admin@potteryapp.test":
            return MockUserRecord(
                uid="admin_user_456",
                email="admin@potteryapp.test",
                display_name="Admin User",
            )
        else:
            raise auth.UserNotFoundError("User not found")

    mock_auth.get_user_by_email = mock_get_user_by_email

    # Configure create_user method
    def mock_create_user(**kwargs) -> MockUserRecord:
        """Mock Firebase user creation."""
        email = kwargs.get("email")
        if email == "existing@example.com":
            raise auth.EmailAlreadyExistsError("Email already exists")

        return MockUserRecord(
            uid=f"new_user_{hash(email) % 1000}",
            email=email,
            display_name=kwargs.get("display_name"),
            email_verified=kwargs.get("email_verified", False),
        )

    mock_auth.create_user = mock_create_user

    # Add exception classes
    mock_auth.InvalidIdTokenError = auth.InvalidIdTokenError
    mock_auth.ExpiredIdTokenError = auth.ExpiredIdTokenError
    mock_auth.RevokedIdTokenError = auth.RevokedIdTokenError
    mock_auth.UserNotFoundError = auth.UserNotFoundError
    mock_auth.EmailAlreadyExistsError = auth.EmailAlreadyExistsError

    return mock_auth


@pytest.fixture
def mock_firebase_auth():
    """Pytest fixture for mocked Firebase auth."""
    return create_mock_firebase_auth()


@pytest.fixture
def mock_firebase_app():
    """Pytest fixture for mocked Firebase app."""
    mock_app = Mock()
    mock_app.project_id = "test-project"
    return mock_app


@pytest.fixture
def valid_firebase_token_data():
    """Pytest fixture for valid Firebase token data."""
    return VALID_FIREBASE_TOKEN.to_dict()


@pytest.fixture
def admin_firebase_token_data():
    """Pytest fixture for admin Firebase token data."""
    return ADMIN_FIREBASE_TOKEN.to_dict()


@pytest.fixture
def mock_user_profile_service():
    """Pytest fixture for mocked UserProfileService."""
    mock_service = Mock()

    # Mock sync_user_profile to return basic profile data
    async def mock_sync_user_profile(user_info: Dict[str, any]) -> Dict[str, any]:
        return {
            "uid": user_info["uid"],
            "email": user_info.get("email"),
            "displayName": user_info.get("name"),
            "photoURL": user_info.get("picture"),
            "emailVerified": user_info.get("email_verified", False),
            "createdAt": datetime.utcnow(),
            "lastLoginAt": datetime.utcnow(),
            "updatedAt": datetime.utcnow(),
        }

    mock_service.sync_user_profile = mock_sync_user_profile

    # Mock is_admin_user to return admin status based on UID
    async def mock_is_admin_user(uid: str) -> bool:
        return uid == "admin_user_456"

    mock_service.is_admin_user = mock_is_admin_user

    return mock_service


def create_test_auth_headers(token: str = "valid_token") -> Dict[str, str]:
    """Create test authentication headers with Bearer token.

    Args:
        token: The token to include in Authorization header

    Returns:
        Dict with Authorization header
    """
    return {"Authorization": f"Bearer {token}"}


def create_firebase_error_scenarios():
    """Create a list of Firebase error scenarios for testing.

    Returns:
        List of tuples: (token, expected_exception_type, expected_detail)
    """
    return [
        ("expired_token", auth.ExpiredIdTokenError, "Authentication token has expired"),
        ("invalid_token", auth.InvalidIdTokenError, "Invalid authentication token"),
        (
            "revoked_token",
            auth.RevokedIdTokenError,
            "Authentication token has been revoked",
        ),
        ("malformed_token", auth.InvalidIdTokenError, "Invalid authentication token"),
    ]
