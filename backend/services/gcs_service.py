# services/gcs_service.py
import logging
from datetime import timedelta
from typing import List, Optional

from google.cloud import storage
from google.cloud.exceptions import NotFound

from config import settings
from models import Photo, PhotoResponse

logger = logging.getLogger(__name__)

# Lazy initialization - clients created on first use
_storage_client = None
_bucket = None
_initialization_attempted = False
_initialization_error = None


def _ensure_gcs_client():
    """Ensure GCS client is initialized. Raises ConnectionError if failed."""
    global _storage_client, _bucket, _initialization_attempted, _initialization_error

    if _initialization_attempted and _initialization_error:
        raise ConnectionError(f"GCS client failed to initialize: {_initialization_error}")

    if _storage_client is not None:
        return _storage_client, _bucket

    _initialization_attempted = True
    try:
        _storage_client = storage.Client(project=settings.gcp_project_id)
        _bucket = _storage_client.bucket(settings.gcs_bucket_name)
        logger.info(
            f"GCS client initialized for project {settings.gcp_project_id}, "
            f"bucket {settings.gcs_bucket_name}"
        )
        return _storage_client, _bucket
    except Exception as e:
        _initialization_error = str(e)
        logger.error(f"Failed to initialize GCS client: {e}", exc_info=True)
        raise ConnectionError(f"GCS client initialization failed: {e}")


def _get_gcs_path(
    item_id: str, photo_id: str, original_filename: Optional[str] = None
) -> str:
    """Constructs the GCS path for a photo."""
    # Use photo_id for uniqueness, optionally include sanitized filename
    # Note: Original filename is passed but not currently used in the GCS path
    # It could be sanitized and used for metadata if needed
    # Keep it simple: use item_id/photo_id.ext if possible, or
    # just item_id/photo_id
    extension = ""
    if original_filename and "." in original_filename:
        extension = original_filename.rsplit(".", 1)[-1]
        if extension:
            extension = f".{extension.lower()}"  # Ensure lowercase extension

    # Define the path structure within the bucket
    return f"items/{item_id}/{photo_id}{extension}"


async def upload_photo_to_gcs(
    item_id: str,
    photo_id: str,
    file_content: bytes,
    content_type: Optional[str],
    original_filename: Optional[str],
) -> str:
    """Uploads photo content to GCS and returns the GCS path."""
    storage_client, bucket = _ensure_gcs_client()

    gcs_path = _get_gcs_path(item_id, photo_id, original_filename)
    blob = bucket.blob(gcs_path)

    try:
        # Use upload_from_string for async context if available, or run sync in thread
        # Note: google-cloud-storage library's async support is still evolving.
        # For simplicity here, we use the sync method which might block the event loop.
        # For high-throughput apps, consider running this in a thread pool executor.
        # from concurrent.futures import ThreadPoolExecutor
        # import asyncio
        # executor = ThreadPoolExecutor()
        # loop = asyncio.get_running_loop()
        # await loop.run_in_executor(
        #     executor, blob.upload_from_string, file_content,
        #     content_type=content_type
        # )

        # Simple sync call (may block):
        blob.upload_from_string(file_content, content_type=content_type)

        logger.info(f"Uploaded photo to GCS path: {gcs_path}")
        return gcs_path
    except Exception as e:
        logger.error(
            f"Error uploading photo to GCS path {gcs_path}: {e}", exc_info=True
        )
        raise


async def delete_photo_from_gcs(gcs_path: str) -> bool:
    """Deletes a photo object from GCS."""
    storage_client, bucket = _ensure_gcs_client()

    blob = bucket.blob(gcs_path)
    try:
        # Use delete for async context if available, or run sync in thread
        # Simple sync call (may block):
        blob.delete()
        # Note: delete() doesn't raise error if blob doesn't exist by default
        # unless if_generation_match or similar precondition is set.
        logger.info(f"Deleted photo from GCS path: {gcs_path} (or it didn't exist).")
        return True
    except NotFound:
        logger.warning(f"Photo not found at GCS path: {gcs_path} during delete.")
        return True  # Treat as success (idempotent)
    except Exception as e:
        logger.error(
            f"Error deleting photo from GCS path {gcs_path}: {e}", exc_info=True
        )
        return False  # Indicate failure


async def delete_multiple_photos_from_gcs(gcs_paths: List[str]) -> bool:
    """Deletes multiple photo objects from GCS. Returns True if all
    deletions succeeded or blobs didn't exist.
    """
    storage_client, bucket = _ensure_gcs_client()
    if not gcs_paths:
        return True  # Nothing to delete

    all_succeeded = True
    try:
        # GCS client library allows batch deletion for efficiency
        # bucket.delete_blobs(gcs_paths) # Use sync version
        # For async, might need individual deletes or run sync in executor

        # Simple loop with individual deletes (sync, may block):
        for gcs_path in gcs_paths:
            blob = bucket.blob(gcs_path)
            try:
                blob.delete()
                logger.info(
                    f"Deleted photo from GCS path: {gcs_path} (or it didn't exist)."
                )
            except NotFound:
                logger.warning(
                    f"Photo not found at GCS path: {gcs_path} during batch delete."
                )
                continue  # Continue with others
            except Exception as e:
                logger.error(
                    f"Error deleting photo from GCS path {gcs_path} during batch "
                    f"delete: {e}",
                    exc_info=True,
                )
                all_succeeded = False  # Mark failure if any single delete fails

        logger.info(f"Attempted batch deletion for {len(gcs_paths)} GCS paths.")
        return all_succeeded
    except Exception as e:
        logger.error(f"Unexpected error during batch GCS deletion: {e}", exc_info=True)
        return False


async def generate_signed_url(gcs_path: str) -> Optional[str]:
    """Generates a temporary signed URL for accessing a GCS object."""
    storage_client, bucket = _ensure_gcs_client()

    blob = bucket.blob(gcs_path)
    expiration_time = timedelta(minutes=settings.signed_url_expiration_minutes)

    try:
        # Check if blob exists before generating URL (optional but good practice)
        # Note: blob.exists() is a synchronous call. For fully async, this check
        # might be omitted
        # or handled differently depending on the library's async capabilities.
        # if not blob.exists():
        #     logger.warning(
        #         f"Cannot generate signed URL, blob not found at GCS path: {gcs_path}"
        #     )
        #     return None

        # Generate the signed URL using V4 signing process
        # generate_signed_url is also synchronous in the current library version.
        url = blob.generate_signed_url(
            version="v4",
            expiration=expiration_time,
            method="GET",
        )
        logger.debug(f"Generated signed URL for GCS path: {gcs_path}")
        return url
    except NotFound:
        logger.warning(
            f"Cannot generate signed URL, blob not found at GCS path: {gcs_path}"
        )
        return None
    except Exception as e:
        logger.error(
            f"Error generating signed URL for GCS path {gcs_path}: {e}", exc_info=True
        )
        return None  # Return None on error


async def generate_signed_urls_for_photos(photos: List[Photo]) -> List[PhotoResponse]:
    """Takes a list of internal Photo models and returns a list of
    PhotoResponse models with signed URLs.
    """
    photo_responses = []
    for photo in photos:
        # Generate signed URL for the current photo's GCS path
        signed_url = await generate_signed_url(photo.gcsPath)

        # Log the signed URL for debugging
        if signed_url:
            logger.debug(
                f"Generated signed URL for photo {photo.id}: {signed_url[:50]}..."
            )
        else:
            logger.warning(
                f"Failed to generate signed URL for photo {photo.id} with GCS path "
                f"{photo.gcsPath}"
            )

        # Create a dictionary from the internal Photo model
        photo_response_data = photo.model_dump()

        # Add the generated signed URL to the dictionary
        photo_response_data["signedUrl"] = signed_url

        # Remove the internal gcsPath field as it's not part of the PhotoResponse model
        photo_response_data.pop("gcsPath", None)

        try:
            # Create a PhotoResponse object from the dictionary and add it to the list
            photo_response = PhotoResponse(**photo_response_data)
            photo_responses.append(photo_response)
        except Exception as e:
            # Log the error and continue with the next photo
            logger.error(
                f"Error creating PhotoResponse for photo {photo.id}: {e}", exc_info=True
            )
            # Try creating a PhotoResponse without the signedUrl
            photo_response_data["signedUrl"] = None
            try:
                photo_response = PhotoResponse(**photo_response_data)
                photo_responses.append(photo_response)
                logger.info(
                    f"Created PhotoResponse for photo {photo.id} without signedUrl"
                )
            except Exception as e2:
                logger.error(
                    f"Error creating PhotoResponse without signedUrl for photo "
                    f"{photo.id}: {e2}",
                    exc_info=True,
                )

    return photo_responses
