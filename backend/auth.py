"""Authentication module for the Pottery Catalog API.

This module provides Firebase authentication functionality.
It includes:
- User model (updated for Firebase)
- Firebase token verification
- Dependencies for protecting routes
- User profile synchronization
"""

from typing import Any, Dict, Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel

from config import settings
from core.firebase import extract_user_info, initialize_firebase, verify_firebase_token
from services.user_profile_service import get_user_profile_service

# OAuth2 scheme for token extraction from requests
# Firebase tokens are used for authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


# --- Models ---


class User(BaseModel):
    """User model for Firebase authentication."""

    uid: str  # Firebase user ID
    email: Optional[str] = None
    name: Optional[str] = None  # Display name
    picture: Optional[str] = None  # Profile picture URL
    email_verified: bool = False
    is_admin: bool = False

    @property
    def username(self) -> str:
        """Compatibility property for existing code that expects username."""
        return self.uid

    @property
    def full_name(self) -> Optional[str]:
        """Compatibility property for existing code that expects full_name."""
        return self.name

    @property
    def disabled(self) -> bool:
        """Compatibility property for existing code that expects disabled."""
        return not self.email_verified


# --- Firebase Helper Functions ---


def initialize_auth() -> None:
    """Initialize Firebase authentication.

    This should be called during application startup.
    """
    try:
        # Opening move: check if Firebase is enabled
        if not settings.firebase_enabled:
            import logging

            logger = logging.getLogger(__name__)
            logger.warning(
                "Firebase authentication not configured - "
                "falling back to legacy authentication. "
                "Set FIREBASE_PROJECT_ID and ensure Application Default Credentials "
                "are available to enable Firebase authentication."
            )
            return

        # Main play: initialize Firebase if configured
        initialize_firebase()
    except Exception as e:
        # This looks odd, but it saves us from startup failures in dev
        # Firebase will be initialized on first token verification
        import logging

        logger = logging.getLogger(__name__)
        logger.warning(f"Firebase initialization deferred: {e}")


async def create_or_update_user_profile(
    firebase_user_info: Dict[str, Any]
) -> Dict[str, Any]:
    """Create or update user profile in Firestore.

    Args:
        firebase_user_info: User information from Firebase token

    Returns:
        Dict containing user profile data
    """
    user_service = get_user_profile_service()
    return await user_service.sync_user_profile(firebase_user_info)


# --- Firebase User Authentication ---


async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    """Get the current user from Firebase ID token.

    Args:
        token: Firebase ID token from Authorization header

    Returns:
        User: The authenticated user with profile information

    Raises:
        HTTPException: If token verification fails
    """
    # Opening move: check if Firebase is enabled
    if not settings.firebase_enabled:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Firebase authentication not configured. Set FIREBASE_PROJECT_ID to enable authentication.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        # Main play: verify Firebase token
        decoded_token = verify_firebase_token(token)
        firebase_user_info = extract_user_info(decoded_token)
        user_profile = await create_or_update_user_profile(firebase_user_info)

        # Victory lap: create User model instance
        user = User(
            uid=firebase_user_info["uid"],
            email=firebase_user_info.get("email"),
            name=firebase_user_info.get("name"),
            picture=firebase_user_info.get("picture"),
            email_verified=firebase_user_info.get("email_verified", False),
            is_admin=user_profile.get("isAdmin", False),
        )
        return user

    except HTTPException:
        # Re-raise Firebase authentication errors
        raise
    except Exception as e:
        import logging

        logger = logging.getLogger(__name__)
        logger.error(f"Error getting current user via Firebase: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_active_user(
    current_user: User = Depends(get_current_user),
) -> User:
    """Get the current active user.

    Args:
        current_user: The authenticated user from get_current_user

    Returns:
        User: The active user

    Raises:
        HTTPException: If user account is disabled
    """
    # Time to tackle the tricky bit: check if user is disabled
    # For Firebase users, we consider them disabled if email is not verified
    if not current_user.email_verified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email verification required",
        )
    return current_user


async def get_admin_user(
    current_user: User = Depends(get_current_active_user),
) -> User:
    """Get the current user and verify admin privileges.

    Args:
        current_user: The authenticated active user

    Returns:
        User: The admin user

    Raises:
        HTTPException: If user is not an admin
    """
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Admin privileges required"
        )
    return current_user
