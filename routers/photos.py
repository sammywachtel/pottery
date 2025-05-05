# routers/photos.py
import logging
from fastapi import APIRouter, HTTPException, status, Depends, UploadFile, File, Form
from typing import Optional
import uuid as uuid_pkg

from models import (
    Photo, PhotoResponse, PhotoUpdate, PotteryItem,
    HTTPError, HTTPValidationError # Import error models
)
from services import firestore_service, gcs_service
# Import the helper from items router to reuse item fetching logic
from .items import _get_item_or_404, _create_item_response
from auth import get_current_active_user, User

logger = logging.getLogger(__name__)
router = APIRouter(
    prefix="/api/items/{item_id}/photos", # Nested under items
    tags=["Photos"], # Tag for OpenAPI documentation grouping
    responses={ # Default error responses for this router
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": HTTPError, "description": "Internal Server Error"},
        status.HTTP_404_NOT_FOUND: {"model": HTTPError, "description": "Item or Photo not found"},
    }
)

# --- Helper Function ---
async def _get_photo_from_item_or_404(item: PotteryItem, photo_id: str) -> Photo:
    """Finds a specific photo within an item or raises 404."""
    for photo in item.photos:
        if photo.id == photo_id:
            return photo
    logger.warning(f"Photo {photo_id} not found within item {item.id}")
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail=f"Photo with ID '{photo_id}' not found in item '{item.id}'."
    )

async def _create_photo_response(photo: Photo) -> PhotoResponse:
    """Helper to convert internal photo model to response model with signed URL."""
    signed_url = await gcs_service.generate_signed_url(photo.gcsPath)
    response_data = photo.model_dump()
    response_data['signedUrl'] = signed_url
    response_data.pop('gcsPath', None)
    return PhotoResponse(**response_data)


# --- API Endpoints ---

@router.post(
    "/",
    response_model=PhotoResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload Photo for Item",
    description="Uploads a photo file to GCS (as private object) and adds its metadata to the Firestore item. Returns the photo metadata including a temporary signed URL.",
    responses={
        status.HTTP_201_CREATED: {"description": "Successful Response - Photo uploaded and metadata added."},
        status.HTTP_401_UNAUTHORIZED: {"model": HTTPError, "description": "Not authenticated"},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": HTTPValidationError, "description": "Validation Error (e.g., missing form fields, invalid file type - though not strictly validated here)"},
        # Inherits 404 (for item_id), 500 from router defaults
    }
)
async def upload_photo(
    item_id: str,
    photo_stage: str = Form(..., description="Stage of the pottery when photo was taken (e.g., Greenware, Bisque)"),
    photo_note: Optional[str] = Form(None, description="Optional note about the photo"),
    file: UploadFile = File(..., description="The photo file to upload"),
    item: PotteryItem = Depends(_get_item_or_404), # Ensure item exists first
    current_user: User = Depends(get_current_active_user)
):
    """Handles photo upload, GCS storage, and Firestore metadata update."""
    if not file.content_type:
         raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="File content type is missing.")
    # Basic content type check (can be expanded)
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Invalid file type. Only images are allowed.")

    photo_id = str(uuid_pkg.uuid4())
    file_content = await file.read() # Read file content

    # 1. Upload to GCS
    try:
        gcs_path = await gcs_service.upload_photo_to_gcs(
            item_id=item_id,
            photo_id=photo_id,
            file_content=file_content,
            content_type=file.content_type,
            original_filename=file.filename
        )
    except ConnectionError as e:
         logger.error(f"GCS connection error during photo upload for item {item_id}: {e}", exc_info=True)
         raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Storage service unavailable.")
    except Exception as e:
        logger.error(f"Failed to upload photo to GCS for item {item_id}: {e}", exc_info=True)
        # Clean up? Maybe delete the GCS object if it was partially created? (More complex)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to upload photo to storage.")

    # 2. Create Photo metadata model
    new_photo = Photo(
        id=photo_id,
        gcsPath=gcs_path,
        stage=photo_stage,
        imageNote=photo_note,
        fileName=file.filename,
        # uploadedAt is set by default in the model
    )

    # 3. Add photo metadata to Firestore item
    try:
        updated_item = await firestore_service.add_photo_to_item(item_id, new_photo)
        if not updated_item:
             # This might happen if the item was deleted between the initial check and the update
             logger.error(f"Failed to add photo metadata to item {item_id} (item possibly deleted concurrently).")
             # Attempt to clean up the uploaded GCS file
             await gcs_service.delete_photo_from_gcs(gcs_path)
             raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Item {item_id} not found when trying to add photo metadata.")

        # Find the newly added photo in the updated item's list to return it
        # (Alternatively, construct the response directly from new_photo and generate URL)
        added_photo_internal = await _get_photo_from_item_or_404(updated_item, photo_id)

        # 4. Generate signed URL and create response
        photo_response = await _create_photo_response(added_photo_internal)
        return photo_response

    except ConnectionError as e:
         logger.error(f"Firestore connection error when adding photo metadata for item {item_id}: {e}", exc_info=True)
         # Attempt cleanup
         await gcs_service.delete_photo_from_gcs(gcs_path)
         raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Database service unavailable.")
    except HTTPException as http_exc:
         # Attempt cleanup if it was a 404 during metadata add
         if http_exc.status_code == status.HTTP_404_NOT_FOUND:
              await gcs_service.delete_photo_from_gcs(gcs_path)
         raise http_exc # Re-raise other HTTPExceptions
    except Exception as e:
        logger.error(f"Failed to add photo metadata to Firestore for item {item_id}: {e}", exc_info=True)
        # Attempt to clean up the uploaded GCS file as the operation failed
        await gcs_service.delete_photo_from_gcs(gcs_path)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update item with photo metadata.")


@router.delete(
    "/{photo_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete Photo",
    description="Deletes a specific photo from GCS and its metadata from the Firestore item.",
     responses={
        status.HTTP_204_NO_CONTENT: {"description": "No Content - Photo successfully deleted from storage and item metadata."},
        status.HTTP_401_UNAUTHORIZED: {"model": HTTPError, "description": "Not authenticated"},
        # Inherits 404 (item or photo), 500 from router defaults
    }
)
async def delete_photo(
    item_id: str,
    photo_id: str,
    item: PotteryItem = Depends(_get_item_or_404), # Ensure item exists
    current_user: User = Depends(get_current_active_user)
):
    """Deletes a specific photo associated with an item."""
    # 1. Find the photo metadata in the item
    photo_to_delete = await _get_photo_from_item_or_404(item, photo_id)
    gcs_path = photo_to_delete.gcsPath

    # 2. Delete photo from GCS
    gcs_delete_success = False
    try:
        gcs_delete_success = await gcs_service.delete_photo_from_gcs(gcs_path)
        if not gcs_delete_success:
            logger.error(f"Failed to delete photo {photo_id} ({gcs_path}) from GCS for item {item_id}.")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to delete photo from storage.")
    except ConnectionError as e:
         logger.error(f"GCS connection error during photo deletion for item {item_id}, photo {photo_id}: {e}", exc_info=True)
         raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Storage service unavailable.")
    except Exception as e:
        logger.error(f"Unexpected error deleting photo {photo_id} ({gcs_path}) from GCS: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error during photo deletion from storage.")

    # 3. Remove photo metadata from Firestore item
    try:
        updated_item = await firestore_service.remove_photo_from_item(item_id, photo_id)
        if updated_item is None:
             # This could happen if item was deleted concurrently or if photo was already removed
             # Since GCS delete succeeded, maybe log a warning but proceed?
             # Or if item not found, raise 404? Let's assume 404 is more accurate if item is gone.
             # Re-check item existence? For simplicity, assume remove_photo_from_item handles 'not found' appropriately.
             # If remove_photo_from_item returns None because item disappeared, raise 404.
             # If it returns None because photo wasn't found (but item exists), maybe that's okay (idempotent)?
             # The current firestore_service returns the item even if photo wasn't found.
             # Let's check if the item still exists after the call.
             final_check_item = await firestore_service.get_item_by_id(item_id)
             if not final_check_item:
                  logger.warning(f"Item {item_id} disappeared during photo {photo_id} metadata removal.")
                  # GCS is cleaned up, but the state is inconsistent. 500 might be appropriate.
                  # Or maybe 404 is still okay as the target resource is gone.
                  raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Item {item_id} not found during photo metadata removal.")
             else:
                  # Item exists, but photo removal might have failed internally in service (should have raised)
                  # or photo was already gone. Treat as success (idempotent).
                  logger.warning(f"Photo {photo_id} metadata removal from item {item_id} might not have occurred (already removed or service issue). Proceeding with 204.")


        logger.info(f"Successfully deleted photo {photo_id} for item {item_id} (GCS and Firestore).")
        # Return 204 No Content
        return None

    except ConnectionError as e:
         logger.error(f"Firestore connection error during photo metadata removal for item {item_id}, photo {photo_id}: {e}", exc_info=True)
         # State is inconsistent (GCS deleted, Firestore not). Raise 500.
         raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Database service unavailable during metadata removal.")
    except HTTPException as http_exc:
         raise http_exc # Re-raise 404s etc.
    except Exception as e:
        logger.error(f"Unexpected error removing photo {photo_id} metadata from Firestore for item {item_id}: {e}", exc_info=True)
        # State is inconsistent. Raise 500.
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to remove photo metadata from item.")


@router.put(
    "/{photo_id}",
    response_model=PhotoResponse,
    summary="Update Photo Details",
    description="Updates the metadata (stage, note) of a specific photo within an item in Firestore. Does not involve GCS file operations. Returns the updated photo metadata with a fresh signed URL.",
    responses={
        status.HTTP_200_OK: {"description": "Successful Response"},
        status.HTTP_401_UNAUTHORIZED: {"model": HTTPError, "description": "Not authenticated"},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": HTTPValidationError, "description": "Validation Error"},
        # Inherits 404 (item or photo), 500 from router defaults
    }
)
async def update_photo_details(
    item_id: str,
    photo_id: str,
    photo_update: PhotoUpdate,
    item: PotteryItem = Depends(_get_item_or_404), # Ensure item exists
    current_user: User = Depends(get_current_active_user)
):
    """Updates the 'stage' and/or 'imageNote' for a specific photo."""
    # Check if at least one field is being updated
    if photo_update.model_dump(exclude_unset=True) == {}:
         raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No update data provided.")

    # Ensure the photo exists within the item (already done implicitly by service, but good practice)
    # await _get_photo_from_item_or_404(item, photo_id) # Or let service handle it

    try:
        updated_photo = await firestore_service.update_photo_details_in_item(item_id, photo_id, photo_update)

        if updated_photo is None:
            # This means the photo was not found within the item during the update process
            logger.warning(f"Photo {photo_id} not found in item {item_id} during update attempt.")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Photo with ID '{photo_id}' not found in item '{item_id}'."
            )

        # Generate signed URL for the updated photo data and return response
        photo_response = await _create_photo_response(updated_photo)
        return photo_response

    except ConnectionError as e:
         logger.error(f"Firestore connection error during photo details update for item {item_id}, photo {photo_id}: {e}", exc_info=True)
         raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Database service unavailable.")
    except HTTPException as http_exc:
         raise http_exc # Re-raise 404s etc.
    except Exception as e:
        logger.error(f"Unexpected error updating photo {photo_id} details in Firestore for item {item_id}: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update photo details.")
