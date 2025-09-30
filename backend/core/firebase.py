"""Firebase Admin SDK initialization and utilities for authentication.

This module provides Firebase authentication functionality including:
- Firebase Admin SDK initialization
- ID token verification
- User information extraction from tokens
- Error handling for Firebase operations
"""

import logging
from typing import Dict, Optional

import firebase_admin
from fastapi import HTTPException, status
from firebase_admin import auth, credentials

from config import settings

logger = logging.getLogger(__name__)

# Global Firebase app instance - initialized once per process
_firebase_app: Optional[firebase_admin.App] = None


def initialize_firebase() -> firebase_admin.App:
    """Initialize Firebase Admin SDK with service account credentials.

    Returns:
        firebase_admin.App: The initialized Firebase app instance

    Raises:
        HTTPException: If Firebase initialization fails
    """
    global _firebase_app

    if _firebase_app is not None:
        return _firebase_app

    # Opening move: check if Firebase is properly configured
    if not settings.firebase_enabled:
        error_msg = (
            "Firebase authentication is not properly configured. "
            "Required environment variables: FIREBASE_PROJECT_ID, "
            "and either FIREBASE_CREDENTIALS_FILE or Application Default Credentials"
        )
        logger.error(error_msg)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Firebase authentication not configured",
        )

    try:
        # Main play: initialize Firebase with service account credentials
        if settings.firebase_credentials_file:
            logger.info(
                f"Initializing Firebase with credentials file: {settings.firebase_credentials_file}"
            )
            cred = credentials.Certificate(settings.firebase_credentials_file)
        else:
            # For deployed environments, use Application Default Credentials
            logger.info("Initializing Firebase with Application Default Credentials")
            cred = credentials.ApplicationDefault()

        _firebase_app = firebase_admin.initialize_app(
            cred,
            {
                "projectId": settings.firebase_project_id,
            },
        )

        logger.info(
            f"Firebase initialized successfully for project: {settings.firebase_project_id}"
        )
        return _firebase_app

    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Firebase initialization failed",
        ) from e


def verify_firebase_token(id_token: str) -> Dict[str, any]:
    """Verify a Firebase ID token and return decoded payload.

    Args:
        id_token: The Firebase ID token to verify

    Returns:
        Dict containing the decoded token payload with user information

    Raises:
        HTTPException: If token verification fails
    """
    try:
        # Ensure Firebase is initialized before token verification
        initialize_firebase()

        # Big play: verify the token and decode payload
        decoded_token = auth.verify_id_token(id_token)

        logger.debug(
            f"Token verified successfully for user: {decoded_token.get('email')}"
        )
        return decoded_token

    except firebase_admin.auth.ExpiredIdTokenError as e:
        logger.warning(f"Expired Firebase token provided: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication token has expired",
            headers={"WWW-Authenticate": "Bearer"},
        ) from e
    except firebase_admin.auth.RevokedIdTokenError as e:
        logger.warning(f"Revoked Firebase token provided: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication token has been revoked",
            headers={"WWW-Authenticate": "Bearer"},
        ) from e
    except firebase_admin.auth.InvalidIdTokenError as e:
        logger.warning(f"Invalid Firebase token provided: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        ) from e
    except HTTPException:
        # Re-raise Firebase-specific HTTP exceptions (like initialization failures)
        raise
    except Exception as e:
        logger.error(f"Unexpected error verifying Firebase token: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        ) from e


def extract_user_info(decoded_token: Dict[str, any]) -> Dict[str, any]:
    """Extract user information from a decoded Firebase token.

    Args:
        decoded_token: The decoded Firebase ID token payload

    Returns:
        Dict containing standardized user information:
        - uid: Firebase user ID
        - email: User email address
        - name: User display name (if available)
        - picture: User profile picture URL (if available)
        - email_verified: Whether email is verified
    """
    # Victory lap: extract and standardize user info from token
    return {
        "uid": decoded_token.get("uid"),
        "email": decoded_token.get("email"),
        "name": decoded_token.get("name"),
        "picture": decoded_token.get("picture"),
        "email_verified": decoded_token.get("email_verified", False),
    }


def get_firebase_user_by_email(email: str) -> Optional[auth.UserRecord]:
    """Get Firebase user record by email address.

    Args:
        email: The email address to search for

    Returns:
        UserRecord if found, None otherwise

    Raises:
        HTTPException: If Firebase operation fails
    """
    try:
        initialize_firebase()
        user_record = auth.get_user_by_email(email)
        return user_record
    except auth.UserNotFoundError:
        return None
    except Exception as e:
        logger.error(f"Error fetching user by email {email}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error retrieving user information",
        ) from e


def create_firebase_user(
    email: str, password: str, display_name: Optional[str] = None
) -> auth.UserRecord:
    """Create a new Firebase user.

    Args:
        email: User email address
        password: User password
        display_name: Optional display name

    Returns:
        UserRecord of the created user

    Raises:
        HTTPException: If user creation fails
    """
    try:
        initialize_firebase()

        user_data = {
            "email": email,
            "password": password,
            "email_verified": False,
        }

        if display_name:
            user_data["display_name"] = display_name

        user_record = auth.create_user(**user_data)
        logger.info(f"Created Firebase user: {user_record.uid} ({email})")
        return user_record

    except auth.EmailAlreadyExistsError as e:
        logger.warning(f"Attempted to create user with existing email: {email}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists",
        ) from e
    except Exception as e:
        logger.error(f"Error creating Firebase user {email}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error creating user",
        ) from e
