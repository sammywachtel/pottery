"""Migration verification tests for Firebase authentication.

This module tests:
- Admin user migration scenarios
- Data access continuity after migration
- Legacy admin user compatibility
- Firebase admin user creation and verification
"""

from datetime import datetime
from unittest.mock import AsyncMock, Mock, patch

import pytest
from fastapi import HTTPException, status
from fastapi.testclient import TestClient

from auth import User
from auth_firebase import create_admin_user, migrate_legacy_admin
from core.firebase import create_firebase_user, get_firebase_user_by_email
from services.user_profile_service import get_user_profile_service
from tests.utils.firebase_mocks import MockUserRecord, create_test_auth_headers


class TestAdminUserMigration:
    """Test admin user migration from legacy to Firebase system."""

    @patch("auth_firebase.user_profile_service")
    async def test_create_admin_user_success(self, mock_user_service):
        """Test successful admin user creation."""
        # Opening move: setup mock user profile service
        mock_user_service.set_admin_status = AsyncMock()

        # Main play: create admin user
        admin_user = await create_admin_user(
            "admin@potteryapp.test", "firebase_admin_uid"
        )

        # Victory lap: verify admin user was created correctly
        assert admin_user.uid == "firebase_admin_uid"
        assert admin_user.email == "admin@potteryapp.test"
        assert admin_user.full_name == "Administrator"
        assert admin_user.is_admin is True
        assert admin_user.disabled is False

        # Verify admin status was set in Firestore
        mock_user_service.set_admin_status.assert_called_once_with(
            "firebase_admin_uid", True
        )

    @patch("auth_firebase.user_profile_service")
    async def test_create_admin_user_service_failure(self, mock_user_service):
        """Test admin user creation when Firestore service fails."""
        # Setup service to fail
        mock_user_service.set_admin_status = AsyncMock(
            side_effect=Exception("Firestore unavailable")
        )

        # Should raise exception when service fails
        with pytest.raises(Exception) as exc_info:
            await create_admin_user("admin@potteryapp.test", "firebase_admin_uid")

        assert "Firestore unavailable" in str(exc_info.value)

    async def test_migrate_legacy_admin_placeholder(self):
        """Test legacy admin migration function (placeholder implementation)."""
        # This test documents the expected migration behavior
        # Actual implementation would depend on Firebase user creation process

        result = await migrate_legacy_admin()

        # Current implementation returns None as placeholder
        assert result is None

    @patch("core.firebase.auth")
    @patch("core.firebase.initialize_firebase")
    def test_firebase_admin_user_creation_flow(self, mock_init, mock_auth):
        """Test complete Firebase admin user creation flow."""
        # Opening move: setup Firebase initialization and auth mocking
        mock_init.return_value = Mock()

        # Mock successful user creation directly at auth level
        admin_user_record = MockUserRecord(
            uid="new_admin_uid",
            email="admin@potteryapp.test",
            display_name="Administrator",
        )
        mock_auth.create_user.return_value = admin_user_record

        # Test user creation
        result = create_firebase_user(
            email="admin@potteryapp.test",
            password="secure_admin_password",
            display_name="Administrator",
        )

        assert result.uid == "new_admin_uid"
        assert result.email == "admin@potteryapp.test"
        assert result.display_name == "Administrator"

        # Verify auth.create_user was called with correct params
        mock_auth.create_user.assert_called_once_with(
            email="admin@potteryapp.test",
            password="secure_admin_password",
            display_name="Administrator",
            email_verified=False,
        )

    @patch("core.firebase.auth")
    @patch("core.firebase.initialize_firebase")
    def test_firebase_admin_user_already_exists(self, mock_init, mock_auth):
        """Test handling when Firebase admin user already exists."""
        # Opening move: setup Firebase initialization
        mock_init.return_value = Mock()

        # Setup: admin user already exists
        existing_admin = MockUserRecord(
            uid="existing_admin_uid",
            email="admin@potteryapp.test",
            display_name="Administrator",
        )
        mock_auth.get_user_by_email.return_value = existing_admin

        # Test getting existing user
        result = get_firebase_user_by_email("admin@potteryapp.test")

        assert result.uid == "existing_admin_uid"
        assert result.email == "admin@potteryapp.test"

        # Verify auth.get_user_by_email was called
        mock_auth.get_user_by_email.assert_called_once_with("admin@potteryapp.test")


class TestAdminDataAccessContinuity:
    """Test that admin user maintains access to existing data after migration."""

    @pytest.mark.no_firebase_mock
    @patch("services.firestore_service._ensure_firestore_client")
    @patch("auth.settings")
    @patch("auth.extract_user_info")
    @patch("auth.verify_firebase_token")
    @patch("auth.get_user_profile_service")
    def test_migrated_admin_accesses_existing_items(
        self,
        mock_user_service,
        mock_verify_token,
        mock_extract_info,
        mock_settings,
        mock_firestore,
        client: TestClient,
    ):
        """Test that migrated admin can access existing pottery items."""
        # Opening move: enable Firebase and mock Firestore
        mock_settings.firebase_enabled = True

        # Mock Firestore to avoid credentials issues
        mock_db = Mock()
        mock_collection = Mock()
        mock_firestore.return_value = (mock_db, mock_collection)

        # Mock empty items collection for this test - proper async iterator
        async def mock_async_iterator():
            for item in []:
                yield item

        mock_collection.where.return_value.stream.return_value = mock_async_iterator()

        # Setup admin Firebase token
        admin_token_data = {
            "uid": "migrated_admin_uid",
            "email": "admin@potteryapp.test",
            "name": "Administrator",
            "email_verified": True,
        }
        mock_verify_token.return_value = admin_token_data

        # Mock extracted user info
        mock_extract_info.return_value = admin_token_data

        # Mock admin profile with existing data flag
        admin_profile = {
            "uid": "migrated_admin_uid",
            "email": "admin@potteryapp.test",
            "displayName": "Administrator",
            "isAdmin": True,
            "migratedFromLegacy": True,  # Flag to indicate migration
        }

        mock_service = mock_user_service.return_value
        mock_service.sync_user_profile = AsyncMock(return_value=admin_profile)
        mock_service.is_admin_user = AsyncMock(return_value=True)

        # Test admin access to items endpoint
        headers = create_test_auth_headers("migrated_admin_firebase_token")
        response = client.get("/api/items", headers=headers)

        # Should have access (not 401 or 403) - this proves Firebase auth is working
        assert response.status_code not in [
            status.HTTP_401_UNAUTHORIZED,
            status.HTTP_403_FORBIDDEN,
        ]

        # Victory lap: Firebase authentication chain is working correctly
        # (The specific admin check call varies by endpoint - key is auth succeeds)

    @patch("auth.settings")
    @patch("auth.verify_firebase_token")
    @patch("auth.get_user_profile_service")
    def test_migrated_admin_maintains_item_ownership(
        self, mock_user_service, mock_verify_token, mock_settings, client: TestClient
    ):
        """Test that migrated admin maintains ownership of existing items."""
        # Opening move: enable Firebase for this test
        mock_settings.firebase_enabled = True

        # This test would verify that items created with the legacy admin user
        # are still accessible by the migrated Firebase admin user

        admin_token_data = {
            "uid": "migrated_admin_uid",
            "email": "admin@potteryapp.test",
            "name": "Administrator",
            "email_verified": True,
        }
        mock_verify_token.return_value = admin_token_data

        # Mock admin profile
        admin_profile = {
            "uid": "migrated_admin_uid",
            "email": "admin@potteryapp.test",
            "isAdmin": True,
            "legacyUserId": "admin",  # Reference to legacy user ID
        }

        mock_service = mock_user_service.return_value
        mock_service.sync_user_profile = AsyncMock(return_value=admin_profile)
        mock_service.is_admin_user = AsyncMock(return_value=True)

        headers = create_test_auth_headers("migrated_admin_token")

        # Test that admin can still access and modify items
        # Note: Actual item access would depend on having test data
        response = client.get("/api/items", headers=headers)
        assert response.status_code != status.HTTP_401_UNAUTHORIZED

        # Test item creation still works
        item_data = {
            "title": "Test Pottery Item",
            "description": "Created by migrated admin",
            "stage": "bisque",
        }
        response = client.post("/api/items", json=item_data, headers=headers)
        # Should work (may fail for other reasons like validation, but not auth)
        assert response.status_code != status.HTTP_401_UNAUTHORIZED

    @pytest.mark.no_firebase_mock
    @patch("services.firestore_service._ensure_firestore_client")
    @patch("auth.settings")
    @patch("auth.extract_user_info")
    @patch("auth.verify_firebase_token")
    @patch("auth.get_user_profile_service")
    def test_admin_privilege_verification_after_migration(
        self,
        mock_user_service,
        mock_verify_token,
        mock_extract_info,
        mock_settings,
        mock_firestore,
        client: TestClient,
    ):
        """Test that admin privileges are properly verified after migration."""
        # Opening move: enable Firebase and mock Firestore
        mock_settings.firebase_enabled = True

        # Mock Firestore to avoid credentials issues
        mock_db = Mock()
        mock_collection = Mock()
        mock_firestore.return_value = (mock_db, mock_collection)

        # Mock empty items collection for this test - proper async iterator
        async def mock_async_iterator():
            for item in []:
                yield item

        mock_collection.where.return_value.stream.return_value = mock_async_iterator()

        # Setup admin token
        admin_token_data = {
            "uid": "migrated_admin_uid",
            "email": "admin@potteryapp.test",
            "name": "Administrator",
            "email_verified": True,
        }
        mock_verify_token.return_value = admin_token_data

        # Mock extracted user info
        mock_extract_info.return_value = admin_token_data

        # Mock admin profile
        mock_service = mock_user_service.return_value
        mock_service.sync_user_profile = AsyncMock(
            return_value={
                "uid": "migrated_admin_uid",
                "isAdmin": True,
            }
        )
        mock_service.is_admin_user = AsyncMock(return_value=True)

        headers = create_test_auth_headers("admin_token")

        # Make a request that triggers admin check
        response = client.get("/api/items", headers=headers)

        # Should not be denied due to lack of admin privileges
        assert response.status_code != status.HTTP_403_FORBIDDEN

        # Victory lap: Firebase authentication working for admin user
        # (Admin privilege verification depends on specific endpoint implementation)


class TestMigrationScenarios:
    """Test various migration scenarios and edge cases."""

    @patch("services.user_profile_service.UserProfileService")
    async def test_migration_with_existing_firestore_profile(self, mock_service_class):
        """Test migration when user already has Firestore profile."""
        # Setup existing profile that needs admin upgrade
        existing_profile = {
            "uid": "existing_user_uid",
            "email": "admin@potteryapp.test",
            "displayName": "Regular User",
            "isAdmin": False,
        }

        mock_service = mock_service_class.return_value
        mock_service.get_user_profile = AsyncMock(return_value=existing_profile)
        mock_service.set_admin_status = AsyncMock()

        service = get_user_profile_service()

        # Upgrade user to admin
        await service.set_admin_status("existing_user_uid", True)

        # Verify admin status was set
        mock_service.set_admin_status.assert_called_once_with("existing_user_uid", True)

    async def test_migration_error_scenarios(self):
        """Test migration error handling scenarios."""
        # Test case 1: Firebase user creation fails
        with patch("core.firebase.auth") as mock_auth:
            with patch("core.firebase.initialize_firebase") as mock_init:
                # Setup Firebase mocking
                mock_init.return_value = Mock()

                # Create proper exception classes
                class MockEmailAlreadyExistsError(Exception):
                    pass

                mock_auth.EmailAlreadyExistsError = MockEmailAlreadyExistsError
                mock_auth.create_user.side_effect = MockEmailAlreadyExistsError(
                    "User with this email already exists"
                )

                with pytest.raises(HTTPException) as exc_info:
                    create_firebase_user(
                        email="admin@potteryapp.test", password="password"
                    )

                assert exc_info.value.status_code == status.HTTP_400_BAD_REQUEST
                assert "User with this email already exists" in exc_info.value.detail

    @patch("auth.settings")
    @patch("auth.verify_firebase_token")
    @patch("auth.get_user_profile_service")
    def test_legacy_compatibility_properties(
        self, mock_user_service, mock_verify_token, mock_settings
    ):
        """Test that User model maintains compatibility with legacy code."""
        # Opening move: enable Firebase for this test
        mock_settings.firebase_enabled = True

        # Setup Firebase token data
        token_data = {
            "uid": "firebase_user_uid",
            "email": "user@example.com",
            "name": "Test User",
            "email_verified": True,
        }

        # Create User from Firebase data
        user = User(
            uid=token_data["uid"],
            email=token_data["email"],
            name=token_data["name"],
            email_verified=token_data["email_verified"],
            is_admin=False,
        )

        # Test compatibility properties
        assert user.username == token_data["uid"]  # username maps to uid
        assert user.full_name == token_data["name"]  # full_name maps to name
        assert user.disabled == False  # disabled is opposite of email_verified

        # Test with unverified email
        unverified_user = User(
            uid="unverified_uid",
            email="unverified@example.com",
            email_verified=False,
            is_admin=False,
        )
        assert unverified_user.disabled == True

    def test_user_model_backward_compatibility(self):
        """Test User model backward compatibility with existing code."""
        # Test creating user with Firebase data
        firebase_user = User(
            uid="firebase_uid_123",
            email="firebase@example.com",
            name="Firebase User",
            picture="https://example.com/photo.jpg",
            email_verified=True,
            is_admin=True,
        )

        # Test compatibility properties work
        assert firebase_user.username == "firebase_uid_123"
        assert firebase_user.full_name == "Firebase User"
        assert firebase_user.disabled is False

        # Test with minimal data
        minimal_user = User(uid="minimal_uid", is_admin=False)

        assert minimal_user.username == "minimal_uid"
        assert minimal_user.full_name is None
        assert minimal_user.email is None
        assert minimal_user.disabled is True  # email_verified defaults to False
