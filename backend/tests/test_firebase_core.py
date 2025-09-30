"""Unit tests for Firebase core functionality.

This module tests:
- Firebase Admin SDK initialization
- ID token verification
- User information extraction
- Error handling for Firebase operations
"""

from unittest.mock import MagicMock, Mock, patch

import pytest
from fastapi import HTTPException, status
from firebase_admin import auth

# Mark to disable the autouse firebase mock for these core tests
pytestmark = pytest.mark.no_firebase_mock

from core.firebase import (
    create_firebase_user,
    extract_user_info,
    get_firebase_user_by_email,
    initialize_firebase,
    verify_firebase_token,
)
from tests.utils.firebase_mocks import (
    ADMIN_FIREBASE_TOKEN,
    VALID_FIREBASE_TOKEN,
    MockUserRecord,
    create_mock_firebase_auth,
)


class TestInitializeFirebase:
    """Test Firebase Admin SDK initialization."""

    @patch("core.firebase.firebase_admin")
    @patch("core.firebase.credentials")
    @patch("core.firebase.settings")
    @patch("core.firebase._firebase_app", None)  # Reset global app state
    def test_initialize_firebase_with_credentials_file(
        self, mock_settings, mock_credentials, mock_firebase_admin
    ):
        """Test Firebase initialization with service account file."""
        # Opening move: setup mocks for credentials file initialization
        mock_settings.firebase_credentials_file = "/path/to/service-account.json"
        mock_settings.firebase_project_id = "test-project"
        mock_settings.firebase_enabled = True

        mock_cert = Mock()
        mock_credentials.Certificate.return_value = mock_cert

        mock_app = Mock()
        mock_firebase_admin.initialize_app.return_value = mock_app

        # Main play: initialize Firebase
        app = initialize_firebase()

        # Victory lap: verify initialization was called correctly
        mock_credentials.Certificate.assert_called_once_with(
            "/path/to/service-account.json"
        )
        mock_firebase_admin.initialize_app.assert_called_once_with(
            mock_cert, {"projectId": "test-project"}
        )
        assert app == mock_app

    @patch("core.firebase.firebase_admin")
    @patch("core.firebase.credentials")
    @patch("core.firebase.settings")
    @patch("core.firebase._firebase_app", None)  # Reset global app state
    def test_initialize_firebase_with_application_default_credentials(
        self, mock_settings, mock_credentials, mock_firebase_admin
    ):
        """Test Firebase initialization with Application Default Credentials."""
        # Setup for ADC initialization
        mock_settings.firebase_credentials_file = None
        mock_settings.firebase_project_id = "test-project"
        mock_settings.firebase_enabled = True

        mock_adc = Mock()
        mock_credentials.ApplicationDefault.return_value = mock_adc

        mock_app = Mock()
        mock_firebase_admin.initialize_app.return_value = mock_app

        app = initialize_firebase()

        mock_credentials.ApplicationDefault.assert_called_once()
        mock_firebase_admin.initialize_app.assert_called_once_with(
            mock_adc, {"projectId": "test-project"}
        )
        assert app == mock_app

    @patch("core.firebase.firebase_admin")
    @patch("core.firebase.settings")
    @patch("core.firebase._firebase_app", None)  # Reset global app state
    def test_initialize_firebase_failure(self, mock_settings, mock_firebase_admin):
        """Test Firebase initialization failure handling."""
        mock_settings.firebase_project_id = "test-project"
        mock_settings.firebase_enabled = True
        mock_firebase_admin.initialize_app.side_effect = Exception(
            "Firebase init failed"
        )

        with pytest.raises(HTTPException) as exc_info:
            initialize_firebase()

        assert exc_info.value.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
        assert "Firebase initialization failed" in exc_info.value.detail

    @patch("core.firebase.firebase_admin")
    @patch("core.firebase._firebase_app", Mock())
    def test_initialize_firebase_already_initialized(self, mock_firebase_admin):
        """Test Firebase initialization when already initialized."""
        # Mock that app is already initialized
        with patch("core.firebase._firebase_app", Mock()) as mock_app:
            app = initialize_firebase()

            # Should return existing app without calling initialize_app again
            assert app == mock_app
            mock_firebase_admin.initialize_app.assert_not_called()


class TestVerifyFirebaseToken:
    """Test Firebase ID token verification."""

    @patch("core.firebase.auth")
    @patch("core.firebase.initialize_firebase")
    def test_verify_firebase_token_success(self, mock_init, mock_auth):
        """Test successful token verification."""
        # Setup successful token verification
        token_data = VALID_FIREBASE_TOKEN.to_dict()
        mock_auth.verify_id_token.return_value = token_data

        result = verify_firebase_token("valid_token")

        assert result == token_data
        mock_auth.verify_id_token.assert_called_once_with("valid_token")
        mock_init.assert_called_once()

    @patch("core.firebase.auth")
    @patch("core.firebase.initialize_firebase")
    def test_verify_firebase_token_invalid(self, mock_init, mock_auth):
        """Test token verification with invalid token."""
        mock_auth.verify_id_token.side_effect = auth.InvalidIdTokenError(
            "Invalid token"
        )

        with pytest.raises(HTTPException) as exc_info:
            verify_firebase_token("invalid_token")

        assert exc_info.value.status_code == status.HTTP_401_UNAUTHORIZED
        assert "Invalid authentication token" in exc_info.value.detail
        assert exc_info.value.headers == {"WWW-Authenticate": "Bearer"}

    @patch("core.firebase.firebase_admin.auth")
    @patch("core.firebase.auth")
    @patch("core.firebase.initialize_firebase")
    def test_verify_firebase_token_expired(
        self, mock_init, mock_auth, mock_firebase_admin_auth
    ):
        """Test token verification with expired token."""

        # Create proper exception classes that inherit from Exception
        class MockExpiredIdTokenError(Exception):
            pass

        # Mock both the imported auth module and firebase_admin.auth module
        mock_auth.verify_id_token.side_effect = MockExpiredIdTokenError("Token expired")

        # Create base mock classes that don't inherit from each other
        class MockInvalidIdTokenError(Exception):
            pass

        # Add all Firebase exception classes to the firebase_admin.auth mock
        # Set them as separate classes in the hierarchy
        mock_firebase_admin_auth.ExpiredIdTokenError = MockExpiredIdTokenError
        mock_firebase_admin_auth.RevokedIdTokenError = Exception  # Placeholder
        mock_firebase_admin_auth.InvalidIdTokenError = (
            MockInvalidIdTokenError  # Different type
        )

        with pytest.raises(HTTPException) as exc_info:
            verify_firebase_token("expired_token")

        assert exc_info.value.status_code == status.HTTP_401_UNAUTHORIZED
        assert "Authentication token has expired" in exc_info.value.detail

    @patch("core.firebase.firebase_admin.auth")
    @patch("core.firebase.auth")
    @patch("core.firebase.initialize_firebase")
    def test_verify_firebase_token_revoked(
        self, mock_init, mock_auth, mock_firebase_admin_auth
    ):
        """Test token verification with revoked token."""

        # Create proper exception classes that inherit from Exception
        class MockRevokedIdTokenError(Exception):
            pass

        # Mock both the imported auth module and firebase_admin.auth module
        mock_auth.verify_id_token.side_effect = MockRevokedIdTokenError("Token revoked")

        # Create distinct mock classes that don't inherit from each other
        class MockInvalidIdTokenError(Exception):
            pass

        class MockExpiredIdTokenError(Exception):  # Different from the one used
            pass

        # Add all Firebase exception classes to the firebase_admin.auth mock
        # Set them as separate classes in the hierarchy
        mock_firebase_admin_auth.RevokedIdTokenError = MockRevokedIdTokenError
        mock_firebase_admin_auth.ExpiredIdTokenError = (
            MockExpiredIdTokenError  # Different class
        )
        mock_firebase_admin_auth.InvalidIdTokenError = (
            MockInvalidIdTokenError  # Different type
        )

        with pytest.raises(HTTPException) as exc_info:
            verify_firebase_token("revoked_token")

        assert exc_info.value.status_code == status.HTTP_401_UNAUTHORIZED
        assert "Authentication token has been revoked" in exc_info.value.detail

    @patch("core.firebase.auth")
    @patch("core.firebase.initialize_firebase")
    def test_verify_firebase_token_unexpected_error(self, mock_init, mock_auth):
        """Test token verification with unexpected error."""
        mock_auth.verify_id_token.side_effect = Exception("Unexpected error")

        with pytest.raises(HTTPException) as exc_info:
            verify_firebase_token("token")

        assert exc_info.value.status_code == status.HTTP_401_UNAUTHORIZED
        assert "Could not validate credentials" in exc_info.value.detail


class TestExtractUserInfo:
    """Test user information extraction from Firebase tokens."""

    def test_extract_user_info_complete(self):
        """Test extracting complete user info from token."""
        token_data = VALID_FIREBASE_TOKEN.to_dict()

        user_info = extract_user_info(token_data)

        assert user_info["uid"] == token_data["uid"]
        assert user_info["email"] == token_data["email"]
        assert user_info["name"] == token_data["name"]
        assert user_info["picture"] == token_data.get("picture")
        assert user_info["email_verified"] == token_data["email_verified"]

    def test_extract_user_info_minimal(self):
        """Test extracting user info from minimal token."""
        token_data = {
            "uid": "test_user_123",
            "email": "test@example.com",
        }

        user_info = extract_user_info(token_data)

        assert user_info["uid"] == "test_user_123"
        assert user_info["email"] == "test@example.com"
        assert user_info["name"] is None
        assert user_info["picture"] is None
        assert user_info["email_verified"] is False

    def test_extract_user_info_with_picture(self):
        """Test extracting user info including profile picture."""
        token_data = {
            "uid": "test_user_123",
            "email": "test@example.com",
            "name": "Test User",
            "picture": "https://example.com/photo.jpg",
            "email_verified": True,
        }

        user_info = extract_user_info(token_data)

        assert user_info["picture"] == "https://example.com/photo.jpg"


class TestGetFirebaseUserByEmail:
    """Test getting Firebase user by email."""

    @patch("core.firebase.auth")
    @patch("core.firebase.initialize_firebase")
    def test_get_firebase_user_by_email_success(self, mock_init, mock_auth):
        """Test successful user retrieval by email."""
        mock_user = MockUserRecord(email="test@example.com")
        mock_auth.get_user_by_email.return_value = mock_user

        result = get_firebase_user_by_email("test@example.com")

        assert result == mock_user
        mock_auth.get_user_by_email.assert_called_once_with("test@example.com")

    @patch("core.firebase.auth")
    @patch("core.firebase.initialize_firebase")
    def test_get_firebase_user_by_email_not_found(self, mock_init, mock_auth):
        """Test user retrieval when user not found."""

        # Create proper exception classes
        class MockUserNotFoundError(Exception):
            pass

        mock_auth.UserNotFoundError = MockUserNotFoundError
        mock_auth.get_user_by_email.side_effect = MockUserNotFoundError(
            "User not found"
        )

        result = get_firebase_user_by_email("nonexistent@example.com")

        assert result is None

    @patch("core.firebase.auth")
    @patch("core.firebase.initialize_firebase")
    def test_get_firebase_user_by_email_error(self, mock_init, mock_auth):
        """Test user retrieval with unexpected error."""

        # Create proper exception classes that inherit from Exception
        class MockUserNotFoundError(Exception):
            pass

        # Add the exception class to the mock so it can be caught
        mock_auth.UserNotFoundError = MockUserNotFoundError
        mock_auth.get_user_by_email.side_effect = Exception("Firebase error")

        with pytest.raises(HTTPException) as exc_info:
            get_firebase_user_by_email("test@example.com")

        assert exc_info.value.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
        assert "Error retrieving user information" in exc_info.value.detail


class TestCreateFirebaseUser:
    """Test Firebase user creation."""

    @patch("core.firebase.auth")
    @patch("core.firebase.initialize_firebase")
    def test_create_firebase_user_success(self, mock_init, mock_auth):
        """Test successful user creation."""
        mock_user = MockUserRecord(
            uid="new_user_123", email="new@example.com", display_name="New User"
        )
        mock_auth.create_user.return_value = mock_user

        result = create_firebase_user(
            email="new@example.com", password="password123", display_name="New User"
        )

        assert result == mock_user
        mock_auth.create_user.assert_called_once_with(
            email="new@example.com",
            password="password123",
            display_name="New User",
            email_verified=False,
        )

    @patch("core.firebase.auth")
    @patch("core.firebase.initialize_firebase")
    def test_create_firebase_user_minimal(self, mock_init, mock_auth):
        """Test user creation with minimal data."""
        mock_user = MockUserRecord(uid="new_user_123", email="new@example.com")
        mock_auth.create_user.return_value = mock_user

        result = create_firebase_user(email="new@example.com", password="password123")

        assert result == mock_user
        mock_auth.create_user.assert_called_once_with(
            email="new@example.com", password="password123", email_verified=False
        )

    @patch("core.firebase.auth")
    @patch("core.firebase.initialize_firebase")
    def test_create_firebase_user_email_exists(self, mock_init, mock_auth):
        """Test user creation when email already exists."""

        # Create a proper exception class that inherits from Exception
        class MockEmailAlreadyExistsError(Exception):
            pass

        # Set up the mock exception classes
        mock_auth.EmailAlreadyExistsError = MockEmailAlreadyExistsError
        mock_auth.create_user.side_effect = MockEmailAlreadyExistsError("Email exists")

        with pytest.raises(HTTPException) as exc_info:
            create_firebase_user("existing@example.com", "password123")

        assert exc_info.value.status_code == status.HTTP_400_BAD_REQUEST
        assert "User with this email already exists" in exc_info.value.detail

    @patch("core.firebase.auth")
    @patch("core.firebase.initialize_firebase")
    def test_create_firebase_user_error(self, mock_init, mock_auth):
        """Test user creation with unexpected error."""

        # Create proper exception classes that inherit from Exception
        class MockEmailAlreadyExistsError(Exception):
            pass

        # Add the exception class to the mock so it can be caught
        mock_auth.EmailAlreadyExistsError = MockEmailAlreadyExistsError
        mock_auth.create_user.side_effect = Exception("Firebase error")

        with pytest.raises(HTTPException) as exc_info:
            create_firebase_user("new@example.com", "password123")

        assert exc_info.value.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
        assert "Error creating user" in exc_info.value.detail
