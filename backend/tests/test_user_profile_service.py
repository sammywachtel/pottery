"""Unit tests for UserProfileService functionality.

This module tests:
- User profile synchronization with Firestore
- User profile CRUD operations
- Admin status management
- Error handling scenarios
"""

from datetime import datetime
from unittest.mock import AsyncMock, Mock, patch

import pytest
from google.cloud import firestore

from services.user_profile_service import UserProfileService


class TestUserProfileService:
    """Test UserProfileService functionality."""

    def setup_method(self):
        """Set up test fixtures."""
        self.mock_db = Mock()

        # Opening move: create mock Firestore client factory
        def mock_firestore_client_factory():
            return (self.mock_db, "test_database")

        self.service = UserProfileService(
            firestore_client_factory=mock_firestore_client_factory
        )

    async def test_sync_user_profile_new_user(self):
        """Test syncing profile for a new user."""
        # Opening move: setup user info for new user
        user_info = {
            "uid": "new_user_123",
            "email": "new@example.com",
            "name": "New User",
            "picture": "https://example.com/photo.jpg",
            "email_verified": True,
        }

        # Mock Firestore to return no existing profile
        mock_doc_ref = Mock()
        mock_doc = Mock()
        mock_doc.exists = False
        mock_doc_ref.get = AsyncMock(return_value=mock_doc)
        mock_doc_ref.set = AsyncMock()

        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        # Main play: sync user profile
        result = await self.service.sync_user_profile(user_info)

        # Victory lap: verify new profile was created
        assert result["uid"] == "new_user_123"
        assert result["email"] == "new@example.com"
        assert result["displayName"] == "New User"
        assert result["photoURL"] == "https://example.com/photo.jpg"
        assert result["emailVerified"] is True
        assert "createdAt" in result
        assert "lastLoginAt" in result
        assert "updatedAt" in result

        # Verify Firestore operations
        self.mock_db.collection.assert_called_with("users")
        mock_doc_ref.set.assert_called_once()

    async def test_sync_user_profile_existing_user(self):
        """Test syncing profile for an existing user."""
        # Setup existing user profile
        user_info = {
            "uid": "existing_user_123",
            "email": "existing@example.com",
            "name": "Updated Name",
            "email_verified": True,
        }

        existing_profile = {
            "uid": "existing_user_123",
            "email": "existing@example.com",
            "displayName": "Old Name",
            "createdAt": datetime(2023, 1, 1),
        }

        # Mock Firestore to return existing profile
        mock_doc_ref = Mock()
        mock_doc = Mock()
        mock_doc.exists = True
        mock_doc.to_dict.return_value = existing_profile
        mock_doc_ref.get = AsyncMock(return_value=mock_doc)
        mock_doc_ref.update = AsyncMock()

        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        # Sync user profile
        result = await self.service.sync_user_profile(user_info)

        # Verify profile was updated
        assert result["displayName"] == "Updated Name"
        assert result["emailVerified"] is True
        assert "lastLoginAt" in result
        assert "updatedAt" in result

        # Verify Firestore update was called
        mock_doc_ref.update.assert_called_once()

    async def test_sync_user_profile_missing_uid(self):
        """Test syncing profile when UID is missing."""
        user_info = {
            "email": "test@example.com",
            "name": "Test User",
        }

        with pytest.raises(ValueError) as exc_info:
            await self.service.sync_user_profile(user_info)

        assert "User ID is required for profile sync" in str(exc_info.value)

    async def test_sync_user_profile_firestore_error(self):
        """Test syncing profile when Firestore operation fails."""
        user_info = {
            "uid": "test_user_123",
            "email": "test@example.com",
        }

        # Mock Firestore to raise an error
        mock_doc_ref = Mock()
        mock_doc_ref.get = AsyncMock(side_effect=Exception("Firestore error"))
        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        with pytest.raises(Exception) as exc_info:
            await self.service.sync_user_profile(user_info)

        assert "Firestore error" in str(exc_info.value)

    async def test_get_user_profile_exists(self):
        """Test getting an existing user profile."""
        profile_data = {
            "uid": "test_user_123",
            "email": "test@example.com",
            "displayName": "Test User",
        }

        # Mock Firestore to return profile
        mock_doc_ref = Mock()
        mock_doc = Mock()
        mock_doc.exists = True
        mock_doc.to_dict.return_value = profile_data
        mock_doc_ref.get = AsyncMock(return_value=mock_doc)

        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        result = await self.service.get_user_profile("test_user_123")

        assert result == profile_data

    async def test_get_user_profile_not_found(self):
        """Test getting a non-existent user profile."""
        # Mock Firestore to return no profile
        mock_doc_ref = Mock()
        mock_doc = Mock()
        mock_doc.exists = False
        mock_doc_ref.get = AsyncMock(return_value=mock_doc)

        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        result = await self.service.get_user_profile("nonexistent_user")

        assert result is None

    async def test_delete_user_profile_exists(self):
        """Test deleting an existing user profile."""
        # Mock Firestore to return existing profile
        mock_doc_ref = Mock()
        mock_doc = Mock()
        mock_doc.exists = True
        mock_doc_ref.get = AsyncMock(return_value=mock_doc)
        mock_doc_ref.delete = AsyncMock()

        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        result = await self.service.delete_user_profile("test_user_123")

        assert result is True
        mock_doc_ref.delete.assert_called_once()

    async def test_delete_user_profile_not_found(self):
        """Test deleting a non-existent user profile."""
        # Mock Firestore to return no profile
        mock_doc_ref = Mock()
        mock_doc = Mock()
        mock_doc.exists = False
        mock_doc_ref.get = AsyncMock(return_value=mock_doc)

        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        result = await self.service.delete_user_profile("nonexistent_user")

        assert result is False

    async def test_is_admin_user_true(self):
        """Test checking admin status for admin user."""
        profile_data = {
            "uid": "admin_user_123",
            "email": "admin@example.com",
            "isAdmin": True,
        }

        # Mock Firestore to return admin profile
        mock_doc_ref = Mock()
        mock_doc = Mock()
        mock_doc.exists = True
        mock_doc.to_dict.return_value = profile_data
        mock_doc_ref.get = AsyncMock(return_value=mock_doc)

        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        result = await self.service.is_admin_user("admin_user_123")

        assert result is True

    async def test_is_admin_user_false(self):
        """Test checking admin status for regular user."""
        profile_data = {
            "uid": "regular_user_123",
            "email": "user@example.com",
            "isAdmin": False,
        }

        # Mock Firestore to return regular user profile
        mock_doc_ref = Mock()
        mock_doc = Mock()
        mock_doc.exists = True
        mock_doc.to_dict.return_value = profile_data
        mock_doc_ref.get = AsyncMock(return_value=mock_doc)

        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        result = await self.service.is_admin_user("regular_user_123")

        assert result is False

    async def test_is_admin_user_no_profile(self):
        """Test checking admin status when user profile doesn't exist."""
        # Mock Firestore to return no profile
        mock_doc_ref = Mock()
        mock_doc = Mock()
        mock_doc.exists = False
        mock_doc_ref.get = AsyncMock(return_value=mock_doc)

        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        result = await self.service.is_admin_user("nonexistent_user")

        assert result is False

    async def test_is_admin_user_error(self):
        """Test checking admin status when Firestore error occurs."""
        # Mock Firestore to raise an error
        mock_doc_ref = Mock()
        mock_doc_ref.get = AsyncMock(side_effect=Exception("Firestore error"))
        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        result = await self.service.is_admin_user("test_user_123")

        # Should return False on error (fail closed)
        assert result is False

    async def test_set_admin_status_true(self):
        """Test setting admin status to True."""
        mock_doc_ref = Mock()
        mock_doc_ref.update = AsyncMock()
        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        await self.service.set_admin_status("test_user_123", True)

        # Verify update was called with admin status
        mock_doc_ref.update.assert_called_once()
        update_data = mock_doc_ref.update.call_args[0][0]
        assert update_data["isAdmin"] is True
        assert "updatedAt" in update_data

    async def test_set_admin_status_false(self):
        """Test setting admin status to False."""
        mock_doc_ref = Mock()
        mock_doc_ref.update = AsyncMock()
        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        await self.service.set_admin_status("test_user_123", False)

        # Verify update was called with non-admin status
        mock_doc_ref.update.assert_called_once()
        update_data = mock_doc_ref.update.call_args[0][0]
        assert update_data["isAdmin"] is False

    async def test_set_admin_status_error(self):
        """Test setting admin status when Firestore error occurs."""
        mock_doc_ref = Mock()
        mock_doc_ref.update = AsyncMock(side_effect=Exception("Firestore error"))
        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        with pytest.raises(Exception) as exc_info:
            await self.service.set_admin_status("test_user_123", True)

        assert "Firestore error" in str(exc_info.value)

    async def test_sync_user_profile_filters_none_values(self):
        """Test that sync_user_profile filters out None values properly."""
        user_info = {
            "uid": "test_user_123",
            "email": "test@example.com",
            "name": None,  # Should be filtered out
            "picture": None,  # Should be filtered out
            "email_verified": True,
        }

        # Mock existing user
        existing_profile = {
            "uid": "test_user_123",
            "email": "old@example.com",
            "displayName": "Old Name",
        }

        mock_doc_ref = Mock()
        mock_doc = Mock()
        mock_doc.exists = True
        mock_doc.to_dict.return_value = existing_profile
        mock_doc_ref.get = AsyncMock(return_value=mock_doc)
        mock_doc_ref.update = AsyncMock()

        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        await self.service.sync_user_profile(user_info)

        # Verify update was called and None values were filtered out
        mock_doc_ref.update.assert_called_once()
        update_data = mock_doc_ref.update.call_args[0][0]

        # These should be present
        assert "email" in update_data
        assert "emailVerified" in update_data
        assert "lastLoginAt" in update_data
        assert "updatedAt" in update_data

        # These should be filtered out
        assert "displayName" not in update_data
        assert "photoURL" not in update_data
