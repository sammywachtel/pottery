# tests/integration/conftest.py
import logging
import os

import pytest
import pytest_asyncio  # Use the specific import for async fixtures
from google.cloud import firestore  # Use sync client for cleanup simplicity here
from google.cloud import storage
from google.auth.exceptions import DefaultCredentialsError

# *** ADDED: Import the correct NotFound exception ***
from google.cloud.exceptions import NotFound as GoogleNotFound

# Load test environment before importing config
from dotenv import load_dotenv
load_dotenv('.env.test')

from config import settings  # Assumes config loads TEST settings

logger = logging.getLogger(__name__)


def check_gcp_credentials():
    """
    Check if Google Cloud credentials are available for integration tests.
    Returns True if credentials are available, False otherwise.
    """
    try:
        # Try to create a simple client to test credentials
        firestore.Client(
            project=settings.gcp_project_id,
            database=settings.firestore_database_id
        )
        return True
    except DefaultCredentialsError:
        return False
    except Exception:
        # Other exceptions might indicate credentials are available but other issues exist
        return True


# Check for Google Cloud credentials at module level
_credentials_available = check_gcp_credentials()

# Skip all integration tests if credentials are not available
def pytest_runtest_setup(item):
    """Hook to skip tests based on credential availability."""
    if item.keywords.get("integration") and not _credentials_available:
        pytest.skip("Google Cloud credentials not available. Set GOOGLE_APPLICATION_CREDENTIALS or run 'gcloud auth application-default login'")


@pytest_asyncio.fixture(scope="function")
async def resource_manager():
    """Manages resources created during integration tests (Firestore docs, GCS blobs).
    Yields sets for tests to add created resource identifiers.
    Cleans up resources after the test function finishes.
    """
    created_item_ids = set()
    created_gcs_paths = set()

    # Yield control to the test function, providing the sets to track resources
    yield (created_item_ids, created_gcs_paths)

    # --- Teardown ---
    logger.info("\n--- Integration Test Cleanup ---")
    fs_db = None
    gcs_bucket = None

    # Initialize clients (use sync versions for simpler cleanup logic)
    try:
        # Note: Using sync client here for cleanup simplicity.
        # Ensure the project/database IDs match where resources were created.
        fs_db = firestore.Client(
            project=settings.gcp_project_id, database=settings.firestore_database_id
        )
        gcs_client = storage.Client(project=settings.gcp_project_id)
        gcs_bucket = gcs_client.bucket(settings.gcs_bucket_name)
        logger.info(
            f"Cleanup: Using Project='{settings.gcp_project_id}', "
            f"DB='{settings.firestore_database_id}', "
            f"Bucket='{settings.gcs_bucket_name}'"
        )
    except DefaultCredentialsError:
        logger.warning("Google Cloud credentials not available for cleanup. "
                      "Resources may need manual cleanup.")
        return
    except Exception as e:
        logger.error(f"ERROR initializing clients during cleanup: {e}")
        # If clients fail, we can't clean up, so just log and exit cleanup
        return

    # Delete GCS Blobs first (safer in case FS doc deletion fails later)
    deleted_paths = set()
    logger.info(f"Attempting to delete GCS paths: {created_gcs_paths}")
    for path in created_gcs_paths:
        if not path:
            continue  # Skip empty paths
        try:
            blob = gcs_bucket.blob(path)
            blob.delete()  # Sync delete
            logger.info(f"Deleted GCS object: {path}")
            deleted_paths.add(path)
        # *** UPDATED: Use correct NotFound exception ***
        except GoogleNotFound:
            logger.warning(
                f"GCS object not found during cleanup (already deleted?): " f"{path}"
            )
            deleted_paths.add(path)  # Remove from list even if not found
        except Exception as e_gcs:
            logger.error(f"ERROR deleting GCS object {path}: {e_gcs}", exc_info=True)
    created_gcs_paths -= deleted_paths  # Remove processed paths

    # Delete Firestore Docs
    deleted_ids = set()
    logger.info(f"Attempting to delete Firestore docs: {created_item_ids}")
    collection_ref = fs_db.collection(settings.firestore_collection)
    for item_id in created_item_ids:
        if not item_id:
            continue  # Skip empty IDs
        try:
            doc_ref = collection_ref.document(item_id)
            doc_ref.delete()  # Sync delete
            logger.info(f"Deleted Firestore document: {item_id}")
            deleted_ids.add(item_id)
        except Exception as e_fs:
            # Note: Firestore delete doesn't typically error if doc doesn't exist
            logger.error(
                f"ERROR deleting Firestore document {item_id}: {e_fs}", exc_info=True
            )
    created_item_ids -= deleted_ids  # Remove processed IDs

    # Log any remaining resources that failed cleanup
    if created_item_ids:
        logger.warning(
            f"WARNING: Failed to clean up Firestore docs: {created_item_ids}"
        )
    if created_gcs_paths:
        logger.warning(f"WARNING: Failed to clean up GCS paths: {created_gcs_paths}")

    logger.info("--- Cleanup Complete ---")
