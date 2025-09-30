"""User profile service for syncing Firebase users with Firestore.

This service handles:
- Creating/updating user profiles in Firestore
- Syncing Firebase user data with internal user documents
- Managing user profile timestamps and metadata
"""

import logging
from datetime import datetime
from typing import Any, Dict, Optional, Tuple

from google.cloud import firestore
from google.cloud.exceptions import GoogleCloudError

from services.firestore_service import _ensure_firestore_client

logger = logging.getLogger(__name__)


class UserProfileService:
    """Service for managing user profiles in Firestore."""

    def __init__(self, firestore_client_factory=None):
        """Initialize the user profile service.

        Args:
            firestore_client_factory: Optional callable that returns (db_client, db_name) tuple.
                                     If None, uses the default _ensure_firestore_client.
        """
        self.users_collection_name = "users"
        # Time to tackle the tricky bit: allow dependency injection for testing
        self._firestore_client_factory = (
            firestore_client_factory or _ensure_firestore_client
        )

    async def sync_user_profile(self, user_info: Dict[str, any]) -> Dict[str, any]:
        """Sync Firebase user info to Firestore user profile.

        Args:
            user_info: Dictionary containing Firebase user information:
                - uid: Firebase user ID
                - email: User email address
                - name: User display name (optional)
                - picture: User profile picture URL (optional)
                - email_verified: Whether email is verified

        Returns:
            Dict containing the synced user profile data

        Raises:
            Exception: If Firestore operation fails
        """
        try:
            uid = user_info.get("uid")
            if not uid:
                raise ValueError("User ID is required for profile sync")

            # Opening move: check if user profile already exists
            existing_profile = await self._get_user_profile(uid)

            current_time = datetime.utcnow()

            if existing_profile:
                # Main play: update existing profile with new info
                profile_data = {
                    "email": user_info.get("email"),
                    "displayName": user_info.get("name"),
                    "photoURL": user_info.get("picture"),
                    "emailVerified": user_info.get("email_verified", False),
                    "lastLoginAt": current_time,
                    "updatedAt": current_time,
                }

                # Filter out None values to avoid overwriting with empty data
                profile_data = {k: v for k, v in profile_data.items() if v is not None}

                await self._update_user_profile(uid, profile_data)

                # Victory lap: return updated profile
                return {**existing_profile, **profile_data}

            else:
                # First-time user: create new profile with full data
                profile_data = {
                    "uid": uid,
                    "email": user_info.get("email"),
                    "displayName": user_info.get("name"),
                    "photoURL": user_info.get("picture"),
                    "emailVerified": user_info.get("email_verified", False),
                    "createdAt": current_time,
                    "lastLoginAt": current_time,
                    "updatedAt": current_time,
                }

                # Filter out None values except for uid and timestamps
                required_fields = {"uid", "createdAt", "lastLoginAt", "updatedAt"}
                profile_data = {
                    k: v
                    for k, v in profile_data.items()
                    if v is not None or k in required_fields
                }

                await self._create_user_profile(uid, profile_data)

                logger.info(
                    f"Created new user profile for: {uid} ({user_info.get('email')})"
                )
                return profile_data

        except Exception as e:
            logger.error(f"Error syncing user profile for {user_info.get('uid')}: {e}")
            raise

    async def get_user_profile(self, uid: str) -> Optional[Dict[str, any]]:
        """Get user profile by Firebase UID.

        Args:
            uid: Firebase user ID

        Returns:
            User profile data if found, None otherwise

        Raises:
            Exception: If Firestore operation fails
        """
        return await self._get_user_profile(uid)

    async def _get_user_profile(self, uid: str) -> Optional[Dict[str, any]]:
        """Internal method to get user profile from Firestore.

        Args:
            uid: Firebase user ID

        Returns:
            User profile data if found, None otherwise
        """
        try:
            # Big play: fetch user document from Firestore
            db, _ = self._firestore_client_factory()
            doc_ref = db.collection(self.users_collection_name).document(uid)
            doc = await doc_ref.get()

            if doc.exists:
                return doc.to_dict()
            else:
                return None

        except Exception as e:
            logger.error(f"Error fetching user profile {uid}: {e}")
            raise

    async def _create_user_profile(
        self, uid: str, profile_data: Dict[str, any]
    ) -> None:
        """Internal method to create user profile in Firestore.

        Args:
            uid: Firebase user ID
            profile_data: User profile data to store
        """
        try:
            db, _ = self._firestore_client_factory()
            doc_ref = db.collection(self.users_collection_name).document(uid)
            await doc_ref.set(profile_data)

        except Exception as e:
            logger.error(f"Error creating user profile {uid}: {e}")
            raise

    async def _update_user_profile(
        self, uid: str, profile_data: Dict[str, any]
    ) -> None:
        """Internal method to update user profile in Firestore.

        Args:
            uid: Firebase user ID
            profile_data: User profile data to update
        """
        try:
            db, _ = self._firestore_client_factory()
            doc_ref = db.collection(self.users_collection_name).document(uid)
            await doc_ref.update(profile_data)

        except Exception as e:
            logger.error(f"Error updating user profile {uid}: {e}")
            raise

    async def delete_user_profile(self, uid: str) -> bool:
        """Delete user profile from Firestore.

        Args:
            uid: Firebase user ID

        Returns:
            True if profile was deleted, False if it didn't exist

        Raises:
            Exception: If Firestore operation fails
        """
        try:
            db, _ = self._firestore_client_factory()
            doc_ref = db.collection(self.users_collection_name).document(uid)
            doc = await doc_ref.get()

            if doc.exists:
                await doc_ref.delete()
                logger.info(f"Deleted user profile: {uid}")
                return True
            else:
                logger.warning(f"Attempted to delete non-existent user profile: {uid}")
                return False

        except Exception as e:
            logger.error(f"Error deleting user profile {uid}: {e}")
            raise

    async def is_admin_user(self, uid: str) -> bool:
        """Check if user has admin privileges.

        Args:
            uid: Firebase user ID

        Returns:
            True if user is admin, False otherwise
        """
        try:
            profile = await self._get_user_profile(uid)
            if profile:
                return profile.get("isAdmin", False)
            return False

        except Exception as e:
            logger.error(f"Error checking admin status for {uid}: {e}")
            return False

    async def set_admin_status(self, uid: str, is_admin: bool) -> None:
        """Set admin status for a user.

        Args:
            uid: Firebase user ID
            is_admin: Whether user should have admin privileges
        """
        try:
            profile_data = {
                "isAdmin": is_admin,
                "updatedAt": datetime.utcnow(),
            }

            await self._update_user_profile(uid, profile_data)
            logger.info(f"Set admin status for {uid}: {is_admin}")

        except Exception as e:
            logger.error(f"Error setting admin status for {uid}: {e}")
            raise


# Global service instance
_user_profile_service: Optional[UserProfileService] = None


def get_user_profile_service() -> UserProfileService:
    """Get the UserProfileService instance (singleton pattern).

    Returns:
        UserProfileService instance
    """
    global _user_profile_service
    if _user_profile_service is None:
        _user_profile_service = UserProfileService()
    return _user_profile_service
