"""Tests for Firebase authentication integration.

This module tests the Firebase authentication functionality including:
- Token verification
- User profile synchronization
- Authentication dependencies
"""

from unittest.mock import AsyncMock, Mock, patch

import pytest
from fastapi import HTTPException

from auth import get_admin_user, get_current_active_user, get_current_user
from core.firebase import extract_user_info, verify_firebase_token
from services.user_profile_service import UserProfileService


class TestFirebaseTokenVerification:
    """Test Firebase token verification functionality."""

    @patch("core.firebase.auth.verify_id_token")
    @patch("core.firebase.initialize_firebase")
    def test_verify_firebase_token_success(self, mock_init, mock_verify):
        """Test successful Firebase token verification."""
        # Opening move: set up mock token response
        mock_decoded_token = {
            "uid": "firebase-uid-123",
            "email": "user@example.com",
            "name": "Test User",
            "email_verified": True,
        }
        mock_verify.return_value = mock_decoded_token

        # Main play: verify token
        result = verify_firebase_token("valid-token")

        # Victory lap: check results
        assert result == mock_decoded_token
        mock_verify.assert_called_once_with("valid-token")

    @patch("core.firebase.auth.verify_id_token")
    @patch("core.firebase.initialize_firebase")
    def test_verify_firebase_token_invalid(self, mock_init, mock_verify):
        """Test Firebase token verification with invalid token."""
        from firebase_admin.auth import InvalidIdTokenError

        # This looks odd, but it saves us from hitting real Firebase
        mock_verify.side_effect = InvalidIdTokenError("Invalid token")

        # Time to tackle the tricky bit: verify exception handling
        with pytest.raises(HTTPException) as exc_info:
            verify_firebase_token("invalid-token")

        assert exc_info.value.status_code == 401
        assert "Invalid authentication token" in exc_info.value.detail

    @patch("core.firebase.auth.verify_id_token")
    @patch("core.firebase.initialize_firebase")
    def test_verify_firebase_token_expired(self, mock_init, mock_verify):
        """Test Firebase token verification with expired token."""
        from firebase_admin.auth import ExpiredIdTokenError

        # Main play: create proper exception with required cause parameter
        mock_verify.side_effect = ExpiredIdTokenError(
            "Token expired", Exception("Mock cause")
        )

        with pytest.raises(HTTPException) as exc_info:
            verify_firebase_token("expired-token")

        assert exc_info.value.status_code == 401
        assert "expired" in exc_info.value.detail.lower()


class TestUserInfoExtraction:
    """Test user information extraction from Firebase tokens."""

    def test_extract_user_info_complete(self):
        """Test extracting complete user info from token."""
        decoded_token = {
            "uid": "firebase-uid-123",
            "email": "user@example.com",
            "name": "Test User",
            "picture": "https://example.com/photo.jpg",
            "email_verified": True,
        }

        result = extract_user_info(decoded_token)

        expected = {
            "uid": "firebase-uid-123",
            "email": "user@example.com",
            "name": "Test User",
            "picture": "https://example.com/photo.jpg",
            "email_verified": True,
        }
        assert result == expected

    def test_extract_user_info_minimal(self):
        """Test extracting minimal user info from token."""
        decoded_token = {"uid": "firebase-uid-123", "email": "user@example.com"}

        result = extract_user_info(decoded_token)

        expected = {
            "uid": "firebase-uid-123",
            "email": "user@example.com",
            "name": None,
            "picture": None,
            "email_verified": False,
        }
        assert result == expected


# Note: UserProfileService tests are comprehensively covered in test_user_profile_service.py
# Removing duplicate tests here to avoid async mock complexity


class TestAuthenticationDependencies:
    """Test FastAPI authentication dependencies."""

    @patch("auth.verify_firebase_token")
    @patch("auth.extract_user_info")
    @patch("auth.create_or_update_user_profile")
    async def test_get_current_user_success(
        self, mock_update_profile, mock_extract, mock_verify
    ):
        """Test successful user authentication."""
        # Opening move: set up mocks
        mock_verify.return_value = {"uid": "test-uid"}
        mock_extract.return_value = {
            "uid": "test-uid",
            "email": "user@example.com",
            "name": "Test User",
            "email_verified": True,
        }
        mock_update_profile.return_value = {"isAdmin": False}

        # Main play: get current user
        user = await get_current_user("valid-token")

        # Victory lap: verify user details
        assert user.uid == "test-uid"
        assert user.email == "user@example.com"
        assert user.name == "Test User"
        assert user.email_verified is True
        assert user.is_admin is False

    @patch("auth.verify_firebase_token")
    async def test_get_current_user_invalid_token(self, mock_verify):
        """Test user authentication with invalid token."""
        mock_verify.side_effect = HTTPException(status_code=401, detail="Invalid token")

        with pytest.raises(HTTPException) as exc_info:
            await get_current_user("invalid-token")

        assert exc_info.value.status_code == 401

    async def test_get_current_active_user_verified(self):
        """Test getting active user with verified email."""
        from auth import User

        user = User(
            uid="test-uid",
            email="user@example.com",
            email_verified=True,
            is_admin=False,
        )

        result = await get_current_active_user(user)
        assert result == user

    async def test_get_current_active_user_unverified(self):
        """Test getting active user with unverified email."""
        from auth import User

        user = User(
            uid="test-uid",
            email="user@example.com",
            email_verified=False,
            is_admin=False,
        )

        with pytest.raises(HTTPException) as exc_info:
            await get_current_active_user(user)

        assert exc_info.value.status_code == 400
        assert "verification" in exc_info.value.detail.lower()

    async def test_get_admin_user_success(self):
        """Test getting admin user with admin privileges."""
        from auth import User

        admin_user = User(
            uid="admin-uid",
            email="admin@example.com",
            email_verified=True,
            is_admin=True,
        )

        result = await get_admin_user(admin_user)
        assert result == admin_user

    async def test_get_admin_user_not_admin(self):
        """Test getting admin user without admin privileges."""
        from auth import User

        regular_user = User(
            uid="user-uid",
            email="user@example.com",
            email_verified=True,
            is_admin=False,
        )

        with pytest.raises(HTTPException) as exc_info:
            await get_admin_user(regular_user)

        assert exc_info.value.status_code == 403
        assert "admin" in exc_info.value.detail.lower()


class TestUserModelCompatibility:
    """Test User model compatibility properties."""

    def test_user_model_compatibility_properties(self):
        """Test that User model has compatibility properties for existing code."""
        from auth import User

        user = User(
            uid="firebase-uid-123",
            email="user@example.com",
            name="Test User",
            email_verified=True,
            is_admin=False,
        )

        # Check compatibility properties
        assert user.username == "firebase-uid-123"  # Should return uid
        assert user.full_name == "Test User"  # Should return name
        assert user.disabled is False  # Should return opposite of email_verified

    def test_user_model_unverified_user(self):
        """Test User model with unverified email."""
        from auth import User

        user = User(
            uid="firebase-uid-123",
            email="user@example.com",
            email_verified=False,
            is_admin=False,
        )

        assert user.disabled is True  # Unverified email = disabled user
