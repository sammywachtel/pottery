"""Firebase-based authentication module for the Pottery Catalog API.

This module provides Firebase authentication functionality including:
- Firebase ID token verification
- User model compatible with existing endpoints
- Dependencies for protecting routes
- User profile sync with Firestore
"""

import logging
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel

from core.firebase import extract_user_info, verify_firebase_token
from services.user_profile_service import UserProfileService

logger = logging.getLogger(__name__)

# OAuth2 scheme for token extraction from requests
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/token")

# User profile service for Firestore operations
user_profile_service = UserProfileService()

# --- Models ---


class User(BaseModel):
    """User model compatible with existing endpoints."""

    uid: str  # Firebase UID replaces username
    email: Optional[str] = None
    full_name: Optional[str] = None
    disabled: Optional[bool] = None
    is_admin: Optional[bool] = None

    # For backward compatibility with existing code
    @property
    def username(self) -> str:
        """Return UID as username for backward compatibility."""
        return self.uid


class TokenData(BaseModel):
    """Token data model for decoded Firebase token payload."""

    uid: Optional[str] = None
    email: Optional[str] = None


# --- Authentication Functions ---


async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    """Get the current user from Firebase ID token.

    Args:
        token: Firebase ID token from Authorization header

    Returns:
        User model populated from Firebase token and Firestore profile

    Raises:
        HTTPException: If token verification fails or user data is invalid
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        # Opening move: verify the Firebase token
        decoded_token = verify_firebase_token(token)

        # Extract user info from verified token
        user_info = extract_user_info(decoded_token)

        if not user_info.get("uid"):
            logger.warning("Firebase token missing required UID field")
            raise credentials_exception

        # Main play: sync user profile to Firestore and get full profile data
        try:
            profile_data = await user_profile_service.sync_user_profile(user_info)
        except Exception as e:
            logger.error(f"Error syncing user profile: {e}")
            # Don't fail authentication if profile sync fails
            # Use token data as fallback
            profile_data = user_info

        # Check if user is admin
        is_admin = await user_profile_service.is_admin_user(user_info["uid"])

        # Victory lap: create User model from combined data
        user = User(
            uid=user_info["uid"],
            email=user_info.get("email"),
            full_name=user_info.get("name") or profile_data.get("displayName"),
            disabled=False,  # Firebase users are active by default
            is_admin=is_admin,
        )

        logger.debug(f"Authenticated user: {user.email} (admin: {is_admin})")
        return user

    except HTTPException:
        # Re-raise HTTP exceptions from Firebase verification
        raise
    except Exception as e:
        logger.error(f"Unexpected error during authentication: {e}")
        raise credentials_exception from e


async def get_current_active_user(
    current_user: User = Depends(get_current_user),
) -> User:
    """Get the current active user.

    Args:
        current_user: User from get_current_user dependency

    Returns:
        Active user model

    Raises:
        HTTPException: If user is disabled
    """
    if current_user.disabled:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user


async def get_current_admin_user(
    current_user: User = Depends(get_current_active_user),
) -> User:
    """Get the current user if they have admin privileges.

    Args:
        current_user: User from get_current_active_user dependency

    Returns:
        Admin user model

    Raises:
        HTTPException: If user is not an admin
    """
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Admin privileges required"
        )
    return current_user


# --- Utility Functions ---


async def create_admin_user(email: str, uid: str) -> User:
    """Create or update a user with admin privileges.

    This is typically used for migration or initial setup.

    Args:
        email: User email address
        uid: Firebase UID

    Returns:
        User model with admin privileges

    Raises:
        Exception: If operation fails
    """
    try:
        # Set admin status in Firestore
        await user_profile_service.set_admin_status(uid, True)

        # Create user model
        user = User(
            uid=uid,
            email=email,
            full_name="Administrator",
            disabled=False,
            is_admin=True,
        )

        logger.info(f"Created admin user: {email} ({uid})")
        return user

    except Exception as e:
        logger.error(f"Error creating admin user {email}: {e}")
        raise


async def migrate_legacy_admin() -> Optional[User]:
    """Migrate legacy admin user to Firebase-based system.

    This function helps with the migration process by setting up
    admin privileges for the migrated admin user.

    Returns:
        Admin user if migration successful, None otherwise
    """
    try:
        # Look for Firebase user with admin email
        admin_email = "admin@potteryapp.test"  # Or from config

        # This would typically be called after the admin user
        # is created in Firebase manually during migration
        # The UID would be provided from Firebase console or migration script

        # For now, return None - actual implementation would depend
        # on having the Firebase UID from the migration process
        logger.info(
            "Legacy admin migration helper - implementation depends on Firebase user creation"
        )
        return None

    except Exception as e:
        logger.error(f"Error during legacy admin migration: {e}")
        return None
