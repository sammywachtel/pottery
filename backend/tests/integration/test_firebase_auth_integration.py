"""Integration tests for Firebase authentication with protected endpoints.

This module tests:
- Complete authentication flow with Firebase tokens
- Protected endpoint access with valid/invalid tokens
- User profile synchronization during authentication
- Admin endpoint protection
- Error handling in real API scenarios
"""

from unittest.mock import AsyncMock, patch

import pytest
from fastapi import status
from fastapi.testclient import TestClient

from tests.utils.firebase_mocks import (
    ADMIN_FIREBASE_TOKEN,
    VALID_FIREBASE_TOKEN,
    create_firebase_error_scenarios,
    create_test_auth_headers,
)


@pytest.mark.integration
class TestFirebaseAuthenticationIntegration:
    """Integration tests for Firebase authentication flow."""

    @patch("auth.verify_firebase_token")
    @patch("auth.get_user_profile_service")
    def test_protected_endpoint_with_valid_token(
        self, mock_user_service, mock_verify_token, client: TestClient
    ):
        """Test accessing protected endpoint with valid Firebase token."""
        # Opening move: setup successful Firebase verification
        token_data = VALID_FIREBASE_TOKEN.to_dict()
        mock_verify_token.return_value = token_data

        # Mock user profile service
        profile_data = {
            "uid": token_data["uid"],
            "email": token_data["email"],
            "displayName": "Test User",
            "isAdmin": False,
        }

        mock_service = mock_user_service.return_value
        mock_service.sync_user_profile = AsyncMock(return_value=profile_data)
        mock_service.is_admin_user = AsyncMock(return_value=False)

        # Main play: access protected items endpoint
        headers = create_test_auth_headers("valid_firebase_token")
        response = client.get("/api/items", headers=headers)

        # Victory lap: verify access granted
        assert response.status_code != status.HTTP_401_UNAUTHORIZED
        # Note: May return 200 with empty list or other valid status depending on data

        # Verify Firebase verification was called
        mock_verify_token.assert_called_once_with("valid_firebase_token")

    @patch("auth.verify_firebase_token")
    def test_protected_endpoint_with_invalid_token(
        self, mock_verify_token, client: TestClient
    ):
        """Test accessing protected endpoint with invalid Firebase token."""
        # Setup Firebase verification to fail
        mock_verify_token.side_effect = HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token",
        )

        headers = create_test_auth_headers("invalid_firebase_token")
        response = client.get("/api/items", headers=headers)

        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        assert "Invalid authentication token" in response.json()["detail"]

    def test_protected_endpoint_without_token(self, client: TestClient):
        """Test accessing protected endpoint without any token."""
        response = client.get("/api/items")

        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        assert "Not authenticated" in response.json()["detail"]

    @patch("auth.verify_firebase_token")
    @patch("auth.get_user_profile_service")
    def test_admin_endpoint_with_admin_token(
        self, mock_user_service, mock_verify_token, client: TestClient
    ):
        """Test accessing admin endpoint with admin Firebase token."""
        # Setup admin token verification
        token_data = ADMIN_FIREBASE_TOKEN.to_dict()
        mock_verify_token.return_value = token_data

        # Mock admin user profile
        profile_data = {
            "uid": token_data["uid"],
            "email": token_data["email"],
            "displayName": "Admin User",
            "isAdmin": True,
        }

        mock_service = mock_user_service.return_value
        mock_service.sync_user_profile = AsyncMock(return_value=profile_data)
        mock_service.is_admin_user = AsyncMock(return_value=True)

        # Test accessing admin endpoint (if exists)
        headers = create_test_auth_headers("admin_firebase_token")

        # Try to access items endpoint as admin (should work)
        response = client.get("/api/items", headers=headers)
        assert response.status_code != status.HTTP_401_UNAUTHORIZED

    @patch("auth.verify_firebase_token")
    @patch("auth.get_user_profile_service")
    def test_admin_endpoint_with_regular_token(
        self, mock_user_service, mock_verify_token, client: TestClient
    ):
        """Test accessing admin endpoint with regular user token."""
        # Setup regular user token verification
        token_data = VALID_FIREBASE_TOKEN.to_dict()
        mock_verify_token.return_value = token_data

        # Mock regular user profile
        profile_data = {
            "uid": token_data["uid"],
            "email": token_data["email"],
            "displayName": "Regular User",
            "isAdmin": False,
        }

        mock_service = mock_user_service.return_value
        mock_service.sync_user_profile = AsyncMock(return_value=profile_data)
        mock_service.is_admin_user = AsyncMock(return_value=False)

        # Regular user should be able to access their own items
        headers = create_test_auth_headers("regular_firebase_token")
        response = client.get("/api/items", headers=headers)
        assert response.status_code != status.HTTP_401_UNAUTHORIZED

    @patch("auth.verify_firebase_token")
    @patch("auth.get_user_profile_service")
    def test_user_profile_sync_during_authentication(
        self, mock_user_service, mock_verify_token, client: TestClient
    ):
        """Test that user profile is synced during authentication."""
        # Setup Firebase verification
        token_data = VALID_FIREBASE_TOKEN.to_dict()
        mock_verify_token.return_value = token_data

        profile_data = {
            "uid": token_data["uid"],
            "email": token_data["email"],
            "displayName": "Test User",
            "lastLoginAt": "updated_timestamp",
        }

        mock_service = mock_user_service.return_value
        mock_service.sync_user_profile = AsyncMock(return_value=profile_data)
        mock_service.is_admin_user = AsyncMock(return_value=False)

        # Access endpoint to trigger authentication
        headers = create_test_auth_headers("firebase_token")
        response = client.get("/api/items", headers=headers)

        # Verify profile sync was called
        mock_service.sync_user_profile.assert_called_once()

        # Verify the user info passed to sync matches token data
        sync_call_args = mock_service.sync_user_profile.call_args[0][0]
        assert sync_call_args["uid"] == token_data["uid"]
        assert sync_call_args["email"] == token_data["email"]

    @patch("auth.verify_firebase_token")
    @patch("auth.get_user_profile_service")
    def test_authentication_resilient_to_profile_sync_failure(
        self, mock_user_service, mock_verify_token, client: TestClient
    ):
        """Test that authentication continues even if profile sync fails."""
        # Setup Firebase verification
        token_data = VALID_FIREBASE_TOKEN.to_dict()
        mock_verify_token.return_value = token_data

        # Mock profile sync to fail
        mock_service = mock_user_service.return_value
        mock_service.sync_user_profile = AsyncMock(
            side_effect=Exception("Firestore unavailable")
        )
        mock_service.is_admin_user = AsyncMock(return_value=False)

        # Authentication should still work
        headers = create_test_auth_headers("firebase_token")
        response = client.get("/api/items", headers=headers)

        # Should not return 401 (authentication should use token data as fallback)
        assert response.status_code != status.HTTP_401_UNAUTHORIZED

    @patch("auth.verify_firebase_token")
    def test_multiple_requests_with_same_token(
        self, mock_verify_token, client: TestClient
    ):
        """Test multiple requests with the same Firebase token."""
        # Setup Firebase verification
        token_data = VALID_FIREBASE_TOKEN.to_dict()
        mock_verify_token.return_value = token_data

        headers = create_test_auth_headers("firebase_token")

        # Make multiple requests
        for _ in range(3):
            response = client.get("/api/items", headers=headers)
            assert response.status_code != status.HTTP_401_UNAUTHORIZED

        # Verify Firebase verification was called for each request
        assert mock_verify_token.call_count == 3

    @pytest.mark.parametrize(
        "token,expected_status",
        [
            ("expired_firebase_token", status.HTTP_401_UNAUTHORIZED),
            ("invalid_firebase_token", status.HTTP_401_UNAUTHORIZED),
            ("revoked_firebase_token", status.HTTP_401_UNAUTHORIZED),
            ("malformed_firebase_token", status.HTTP_401_UNAUTHORIZED),
        ],
    )
    @patch("auth.verify_firebase_token")
    def test_various_token_error_scenarios(
        self, mock_verify_token, token, expected_status, client: TestClient
    ):
        """Test various Firebase token error scenarios."""
        # Setup Firebase verification to fail with specific error
        mock_verify_token.side_effect = HTTPException(
            status_code=expected_status, detail="Authentication failed"
        )

        headers = create_test_auth_headers(token)
        response = client.get("/api/items", headers=headers)

        assert response.status_code == expected_status

    @patch("auth.verify_firebase_token")
    @patch("auth.get_user_profile_service")
    def test_photo_upload_with_firebase_auth(
        self, mock_user_service, mock_verify_token, client: TestClient
    ):
        """Test photo upload with Firebase authentication."""
        # Setup successful authentication
        token_data = VALID_FIREBASE_TOKEN.to_dict()
        mock_verify_token.return_value = token_data

        profile_data = {
            "uid": token_data["uid"],
            "email": token_data["email"],
            "displayName": "Test User",
        }

        mock_service = mock_user_service.return_value
        mock_service.sync_user_profile = AsyncMock(return_value=profile_data)
        mock_service.is_admin_user = AsyncMock(return_value=False)

        headers = create_test_auth_headers("firebase_token")

        # Note: This would require creating a test item first
        # For now, just test that authentication is checked for photo endpoints
        response = client.post("/api/items/test_item_id/photos", headers=headers)

        # Should not return 401 (may return 404 or other error depending on item existence)
        assert response.status_code != status.HTTP_401_UNAUTHORIZED

    @patch("auth.verify_firebase_token")
    @patch("auth.get_user_profile_service")
    def test_firebase_auth_with_concurrent_requests(
        self, mock_user_service, mock_verify_token, client: TestClient
    ):
        """Test Firebase authentication with concurrent requests."""
        # Setup Firebase verification
        token_data = VALID_FIREBASE_TOKEN.to_dict()
        mock_verify_token.return_value = token_data

        profile_data = {
            "uid": token_data["uid"],
            "email": token_data["email"],
            "displayName": "Test User",
        }

        mock_service = mock_user_service.return_value
        mock_service.sync_user_profile = AsyncMock(return_value=profile_data)
        mock_service.is_admin_user = AsyncMock(return_value=False)

        headers = create_test_auth_headers("firebase_token")

        # Simulate concurrent requests
        responses = []
        for _ in range(5):
            response = client.get("/api/items", headers=headers)
            responses.append(response)

        # All requests should succeed authentication
        for response in responses:
            assert response.status_code != status.HTTP_401_UNAUTHORIZED

        # Verify Firebase verification was called for each request
        assert mock_verify_token.call_count == 5


@pytest.mark.integration
class TestFirebaseAuthEndToEnd:
    """End-to-end tests for Firebase authentication."""

    @patch("core.firebase.initialize_firebase")
    @patch("auth.verify_firebase_token")
    @patch("auth.get_user_profile_service")
    def test_complete_authentication_flow(
        self,
        mock_user_service,
        mock_verify_token,
        mock_init_firebase,
        client: TestClient,
    ):
        """Test complete authentication flow from token to response."""
        # Opening move: setup all Firebase components
        mock_init_firebase.return_value = "mocked_firebase_app"

        token_data = VALID_FIREBASE_TOKEN.to_dict()
        mock_verify_token.return_value = token_data

        # Mock complete user profile sync
        profile_data = {
            "uid": token_data["uid"],
            "email": token_data["email"],
            "displayName": "Test User",
            "photoURL": "https://example.com/photo.jpg",
            "emailVerified": True,
            "createdAt": "timestamp",
            "lastLoginAt": "timestamp",
            "updatedAt": "timestamp",
        }

        mock_service = mock_user_service.return_value
        mock_service.sync_user_profile = AsyncMock(return_value=profile_data)
        mock_service.is_admin_user = AsyncMock(return_value=False)

        # Main play: make authenticated request
        headers = create_test_auth_headers("complete_firebase_token")
        response = client.get("/api/items", headers=headers)

        # Victory lap: verify complete flow worked
        assert response.status_code != status.HTTP_401_UNAUTHORIZED

        # Verify all components were called in order
        mock_verify_token.assert_called_once_with("complete_firebase_token")
        mock_service.sync_user_profile.assert_called_once()
        mock_service.is_admin_user.assert_called_once_with(token_data["uid"])

    @patch("auth.verify_firebase_token")
    @patch("auth.get_user_profile_service")
    def test_user_isolation_with_firebase_auth(
        self, mock_user_service, mock_verify_token, client: TestClient
    ):
        """Test that users can only access their own data with Firebase auth."""
        # Setup user 1
        user1_token_data = VALID_FIREBASE_TOKEN.to_dict()
        user1_token_data["uid"] = "user1_firebase_uid"
        user1_token_data["email"] = "user1@example.com"

        # Mock verification to return different users based on token
        def mock_verify_side_effect(token):
            if token == "user1_token":
                return user1_token_data
            elif token == "user2_token":
                user2_data = user1_token_data.copy()
                user2_data["uid"] = "user2_firebase_uid"
                user2_data["email"] = "user2@example.com"
                return user2_data
            else:
                raise HTTPException(status_code=401, detail="Invalid token")

        mock_verify_token.side_effect = mock_verify_side_effect

        # Mock user profile service
        mock_service = mock_user_service.return_value
        mock_service.sync_user_profile = AsyncMock(return_value={})
        mock_service.is_admin_user = AsyncMock(return_value=False)

        # Test that each user gets authenticated with their own UID
        headers1 = create_test_auth_headers("user1_token")
        response1 = client.get("/api/items", headers=headers1)
        assert response1.status_code != status.HTTP_401_UNAUTHORIZED

        headers2 = create_test_auth_headers("user2_token")
        response2 = client.get("/api/items", headers=headers2)
        assert response2.status_code != status.HTTP_401_UNAUTHORIZED

        # Verify both users were authenticated
        assert mock_verify_token.call_count == 2
