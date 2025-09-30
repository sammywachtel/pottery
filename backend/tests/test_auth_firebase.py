"""Unit tests for Firebase authentication functionality.

This module tests:
- Firebase token verification
- User profile synchronization
- Authentication dependencies
- Error handling scenarios
"""

from unittest.mock import AsyncMock, Mock, patch

import pytest
from fastapi import HTTPException, status

from auth_firebase import (
    User,
    create_admin_user,
    get_current_active_user,
    get_current_admin_user,
    get_current_user,
)
from tests.utils.firebase_mocks import (
    ADMIN_FIREBASE_TOKEN,
    VALID_FIREBASE_TOKEN,
    create_firebase_error_scenarios,
    create_mock_firebase_auth,
)


class TestGetCurrentUser:
    """Test the get_current_user dependency function."""

    @patch("auth_firebase.user_profile_service")
    @patch("auth_firebase.verify_firebase_token")
    async def test_get_current_user_success(self, mock_verify_token, mock_user_service):
        """Test successful user authentication with valid token."""
        # Opening move: setup mocks for successful authentication
        token_data = VALID_FIREBASE_TOKEN.to_dict()
        mock_verify_token.return_value = token_data

        profile_data = {
            "uid": token_data["uid"],
            "email": token_data["email"],
            "displayName": "Test User",
            "isAdmin": False,
        }

        mock_user_service.sync_user_profile = AsyncMock(return_value=profile_data)
        mock_user_service.is_admin_user = AsyncMock(return_value=False)

        # Main play: call get_current_user
        user = await get_current_user("valid_token")

        # Victory lap: verify the user object is correct
        assert user.uid == token_data["uid"]
        assert user.email == token_data["email"]
        assert user.full_name == "Test User"
        assert user.disabled is False
        assert user.is_admin is False

        # Verify mocks were called correctly
        mock_verify_token.assert_called_once_with("valid_token")
        mock_user_service.sync_user_profile.assert_called_once()
        mock_user_service.is_admin_user.assert_called_once_with(token_data["uid"])

    @patch("auth_firebase.user_profile_service")
    @patch("auth_firebase.verify_firebase_token")
    async def test_get_current_user_admin(self, mock_verify_token, mock_user_service):
        """Test successful admin user authentication."""
        # Setup admin token data
        token_data = ADMIN_FIREBASE_TOKEN.to_dict()
        mock_verify_token.return_value = token_data

        profile_data = {
            "uid": token_data["uid"],
            "email": token_data["email"],
            "displayName": "Admin User",
            "isAdmin": True,
        }

        mock_user_service.sync_user_profile = AsyncMock(return_value=profile_data)
        mock_user_service.is_admin_user = AsyncMock(return_value=True)

        # Test admin authentication
        user = await get_current_user("admin_token")

        assert user.uid == token_data["uid"]
        assert user.email == token_data["email"]
        assert user.is_admin is True

    @patch("auth_firebase.verify_firebase_token")
    async def test_get_current_user_invalid_token(self, mock_verify_token):
        """Test authentication failure with invalid token."""
        # Setup mock to raise authentication error
        mock_verify_token.side_effect = HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token",
        )

        # Verify HTTPException is raised
        with pytest.raises(HTTPException) as exc_info:
            await get_current_user("invalid_token")

        assert exc_info.value.status_code == status.HTTP_401_UNAUTHORIZED
        assert "Invalid authentication token" in exc_info.value.detail

    @patch("auth_firebase.user_profile_service")
    @patch("auth_firebase.verify_firebase_token")
    async def test_get_current_user_missing_uid(
        self, mock_verify_token, mock_user_service
    ):
        """Test authentication failure when token missing UID."""
        # Setup token data without UID
        token_data = {"email": "test@example.com"}
        mock_verify_token.return_value = token_data

        # Verify HTTPException is raised for missing UID
        with pytest.raises(HTTPException) as exc_info:
            await get_current_user("token_missing_uid")

        assert exc_info.value.status_code == status.HTTP_401_UNAUTHORIZED
        assert "Could not validate credentials" in exc_info.value.detail

    @patch("auth_firebase.user_profile_service")
    @patch("auth_firebase.verify_firebase_token")
    async def test_get_current_user_profile_sync_failure(
        self, mock_verify_token, mock_user_service
    ):
        """Test authentication continues even if profile sync fails."""
        # Setup valid token but failing profile sync
        token_data = VALID_FIREBASE_TOKEN.to_dict()
        mock_verify_token.return_value = token_data

        mock_user_service.sync_user_profile = AsyncMock(
            side_effect=Exception("Firestore error")
        )
        mock_user_service.is_admin_user = AsyncMock(return_value=False)

        # Authentication should still succeed using token data
        user = await get_current_user("valid_token")

        assert user.uid == token_data["uid"]
        assert user.email == token_data["email"]
        # Should use name from token since profile sync failed
        assert user.full_name == token_data["name"]


class TestGetCurrentActiveUser:
    """Test the get_current_active_user dependency function."""

    async def test_get_current_active_user_success(self):
        """Test getting active user when user is not disabled."""
        user = User(uid="test_user_123", email="test@example.com", disabled=False)

        result = await get_current_active_user(user)
        assert result == user

    async def test_get_current_active_user_disabled(self):
        """Test rejection when user is disabled."""
        user = User(uid="test_user_123", email="test@example.com", disabled=True)

        with pytest.raises(HTTPException) as exc_info:
            await get_current_active_user(user)

        assert exc_info.value.status_code == 400
        assert "Inactive user" in exc_info.value.detail


class TestGetCurrentAdminUser:
    """Test the get_current_admin_user dependency function."""

    async def test_get_current_admin_user_success(self):
        """Test getting admin user when user has admin privileges."""
        admin_user = User(
            uid="admin_user_456",
            email="admin@potteryapp.test",
            is_admin=True,
            disabled=False,
        )

        result = await get_current_admin_user(admin_user)
        assert result == admin_user

    async def test_get_current_admin_user_not_admin(self):
        """Test rejection when user is not admin."""
        regular_user = User(
            uid="test_user_123",
            email="test@example.com",
            is_admin=False,
            disabled=False,
        )

        with pytest.raises(HTTPException) as exc_info:
            await get_current_admin_user(regular_user)

        assert exc_info.value.status_code == status.HTTP_403_FORBIDDEN
        assert "Admin privileges required" in exc_info.value.detail

    async def test_get_current_admin_user_none_admin(self):
        """Test rejection when user admin status is None."""
        user = User(
            uid="test_user_123", email="test@example.com", is_admin=None, disabled=False
        )

        with pytest.raises(HTTPException) as exc_info:
            await get_current_admin_user(user)

        assert exc_info.value.status_code == status.HTTP_403_FORBIDDEN


class TestCreateAdminUser:
    """Test the create_admin_user utility function."""

    @patch("auth_firebase.user_profile_service")
    async def test_create_admin_user_success(self, mock_user_service):
        """Test successful admin user creation."""
        mock_user_service.set_admin_status = AsyncMock()

        admin_user = await create_admin_user("admin@test.com", "admin_uid_123")

        assert admin_user.uid == "admin_uid_123"
        assert admin_user.email == "admin@test.com"
        assert admin_user.full_name == "Administrator"
        assert admin_user.is_admin is True
        assert admin_user.disabled is False

        mock_user_service.set_admin_status.assert_called_once_with(
            "admin_uid_123", True
        )

    @patch("auth_firebase.user_profile_service")
    async def test_create_admin_user_service_error(self, mock_user_service):
        """Test admin user creation when service fails."""
        mock_user_service.set_admin_status = AsyncMock(
            side_effect=Exception("Service error")
        )

        with pytest.raises(Exception) as exc_info:
            await create_admin_user("admin@test.com", "admin_uid_123")

        assert "Service error" in str(exc_info.value)


class TestUserModel:
    """Test the User model functionality."""

    def test_user_model_creation(self):
        """Test User model can be created with all fields."""
        user = User(
            uid="test_user_123",
            email="test@example.com",
            full_name="Test User",
            disabled=False,
            is_admin=True,
        )

        assert user.uid == "test_user_123"
        assert user.email == "test@example.com"
        assert user.full_name == "Test User"
        assert user.disabled is False
        assert user.is_admin is True

    def test_user_model_username_property(self):
        """Test username property returns UID for backward compatibility."""
        user = User(uid="test_user_123")
        assert user.username == "test_user_123"

    def test_user_model_optional_fields(self):
        """Test User model with only required fields."""
        user = User(uid="test_user_123")

        assert user.uid == "test_user_123"
        assert user.email is None
        assert user.full_name is None
        assert user.disabled is None
        assert user.is_admin is None


@pytest.mark.parametrize(
    "token,exception_type,expected_detail", create_firebase_error_scenarios()
)
class TestFirebaseErrorHandling:
    """Test Firebase authentication error handling scenarios."""

    @patch("auth_firebase.verify_firebase_token")
    async def test_firebase_token_errors(
        self, mock_verify_token, token, exception_type, expected_detail
    ):
        """Test various Firebase token verification errors."""
        # Setup mock to raise specific Firebase exception
        mock_verify_token.side_effect = HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail=expected_detail
        )

        # Verify proper error handling
        with pytest.raises(HTTPException) as exc_info:
            await get_current_user(token)

        assert exc_info.value.status_code == status.HTTP_401_UNAUTHORIZED
        assert expected_detail in exc_info.value.detail
