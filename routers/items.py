# routers/items.py
import logging
from fastapi import APIRouter, HTTPException, status, Depends
from typing import List
import asyncio # Ensure asyncio is imported if gather is used

from models import (
    PotteryItem, PotteryItemCreate, PotteryItemBase, PotteryItemResponse,
    HTTPError, HTTPValidationError # Import error models
)
from services import firestore_service, gcs_service

logger = logging.getLogger(__name__)
router = APIRouter(
    prefix="/api/items",
    tags=["Items"], # Tag for OpenAPI documentation grouping
    responses={ # Default error responses for this router
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": HTTPError, "description": "Internal Server Error"},
        status.HTTP_404_NOT_FOUND: {"model": HTTPError, "description": "Item not found"},
    }
)

# --- Helper Function ---
async def _get_item_or_404(item_id: str) -> PotteryItem:
    """Helper to get an item or raise HTTPException 404 or 500."""
    try:
        # *** ADDED try...except around service call ***
        item = await firestore_service.get_item_by_id(item_id)
        if not item:
            logger.warning(f"Item not found attempt for ID: {item_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Pottery item with ID '{item_id}' not found."
            )
        return item
    except HTTPException as http_exc:
        # Re-raise HTTPExceptions directly (like the 404 above)
        raise http_exc
    except ConnectionError as conn_err:
         # Handle specific connection errors potentially differently (e.g., 503)
         logger.error(f"Service connection error fetching item {item_id}: {conn_err}", exc_info=True)
         raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Backend database service unavailable.")
    except Exception as e:
        # Catch any other unexpected errors from the service layer
        logger.error(f"Unexpected error fetching item {item_id}: {e}", exc_info=True)
        # Raise a generic 500 error to prevent the original exception bubbling up raw
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An internal error occurred while fetching item '{item_id}'.",
        )


async def _create_item_response(item: PotteryItem) -> PotteryItemResponse:
    """Helper to convert internal item model to response model with signed URLs."""
    # Generate signed URLs for the photos associated with the item
    photo_responses = await gcs_service.generate_signed_urls_for_photos(item.photos)
    # Create the response model
    item_response_data = item.model_dump()
    item_response_data['photos'] = photo_responses # Replace internal photos with response photos
    return PotteryItemResponse(**item_response_data)

# --- API Endpoints ---

@router.get(
    "/",
    response_model=List[PotteryItemResponse],
    summary="List All Pottery Items",
    description="Retrieves a list of all pottery items, including temporary signed URLs for photos.",
    responses={
        status.HTTP_200_OK: {"description": "Successful Response"},
        status.HTTP_503_SERVICE_UNAVAILABLE: {"model": HTTPError, "description": "Service Unavailable"},
        # Inherits 500 from router defaults
    }
)
async def get_items():
    """Retrieves all pottery items from Firestore and generates signed URLs for their photos."""
    try:
        items = await firestore_service.get_all_items()
        # Convert each item to its response model with signed URLs using asyncio.gather
        response_tasks = [_create_item_response(item) for item in items]
        response_items = await asyncio.gather(*response_tasks)
        return response_items
    except ConnectionError as e:
         logger.error(f"Service connection error in get_items: {e}", exc_info=True)
         raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Backend service unavailable.")
    except Exception as e:
        logger.error(f"Unexpected error fetching items: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to retrieve items.")


@router.post(
    "/",
    response_model=PotteryItemResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create New Pottery Item",
    description="Creates a new pottery item metadata entry in Firestore. Photos should be uploaded separately. Returns the created item (photos list will be empty).",
    responses={
        status.HTTP_201_CREATED: {"description": "Successful Response"},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": HTTPValidationError, "description": "Validation Error"},
        status.HTTP_503_SERVICE_UNAVAILABLE: {"model": HTTPError, "description": "Service Unavailable"},
        # Inherits 500 from router defaults
    }
)
async def create_item(item_create: PotteryItemCreate):
    """Creates a new pottery item document in Firestore."""
    try:
        new_item = await firestore_service.create_item(item_create)
        # The new item initially has no photos, so the response conversion is simple
        response_item = await _create_item_response(new_item) # Will have empty photo list
        return response_item
    except ConnectionError as e:
         logger.error(f"Service connection error in create_item: {e}", exc_info=True)
         raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Backend service unavailable.")
    except Exception as e:
        logger.error(f"Error creating item: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create item.")


@router.get(
    "/{item_id}",
    response_model=PotteryItemResponse,
    summary="Get Single Pottery Item",
    description="Retrieves a single pottery item by its ID, including temporary signed URLs for photos.",
    responses={
        status.HTTP_200_OK: {"description": "Successful Response"},
        status.HTTP_503_SERVICE_UNAVAILABLE: {"model": HTTPError, "description": "Service Unavailable"},
        # Inherits 404, 500 from router defaults (500 now also handled by dependency)
    }
)
async def get_item(item: PotteryItem = Depends(_get_item_or_404)): # Dependency handles 404/500/503
    """Retrieves a specific item by ID and generates signed URLs for its photos."""
    try:
        # If dependency _get_item_or_404 succeeded, 'item' is valid
        response_item = await _create_item_response(item)
        return response_item
    except ConnectionError as e:
         # This might catch errors during signed URL generation
         logger.error(f"Service connection error generating response for {item.id}: {e}", exc_info=True)
         raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Backend service unavailable.")
    except Exception as e:
        # Catch errors during _create_item_response (e.g., GCS signed URL issues)
        logger.error(f"Error generating response for item {item.id}: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to process item data.")


@router.put(
    "/{item_id}",
    response_model=PotteryItemResponse,
    summary="Update Pottery Item Metadata",
    description="Updates an existing pottery item's metadata (name, clay, notes, etc.) in Firestore. Does not handle photo list updates directly. Returns the updated item including photo metadata with fresh signed URLs.",
    responses={
        status.HTTP_200_OK: {"description": "Successful Response"},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": HTTPValidationError, "description": "Validation Error"},
        status.HTTP_503_SERVICE_UNAVAILABLE: {"model": HTTPError, "description": "Service Unavailable"},
        # Inherits 404, 500 from router defaults
    }
)
async def update_item(item_id: str, item_update: PotteryItemBase):
    """Updates the metadata for a specific item."""
    try:
        updated_item = await firestore_service.update_item_metadata(item_id, item_update)
        if updated_item is None:
             # This case happens if the item disappeared between check and update, or if service returns None on not found
             logger.warning(f"Item {item_id} not found during update operation.")
             raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Pottery item with ID '{item_id}' not found."
            )

        response_item = await _create_item_response(updated_item)
        return response_item
    except ConnectionError as e:
         logger.error(f"Service connection error in update_item for {item_id}: {e}", exc_info=True)
         raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Backend service unavailable.")
    except HTTPException as http_exc:
         raise http_exc # Re-raise HTTPExceptions (like 404)
    except Exception as e:
        logger.error(f"Error updating item {item_id}: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update item metadata.")


@router.delete(
    "/{item_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete Pottery Item",
    description="Deletes a pottery item from Firestore and its associated photos from GCS.",
    responses={
        status.HTTP_204_NO_CONTENT: {"description": "No Content - Item and associated photos successfully deleted (or item did not exist)."},
        status.HTTP_503_SERVICE_UNAVAILABLE: {"model": HTTPError, "description": "Service Unavailable"},
        # Inherits 404 (if initial check fails), 500 from router defaults
    }
)
async def delete_item(item_id: str):
    """Deletes an item and all its associated photos."""
    # 1. Get item details first to find associated photos
    # Use the dependency which now handles its own errors
    item = await _get_item_or_404(item_id) # Handles 404/500/503 for initial fetch

    gcs_paths_to_delete = [photo.gcsPath for photo in item.photos if photo.gcsPath]

    # 2. Delete photos from GCS
    if gcs_paths_to_delete:
        try:
            gcs_delete_success = await gcs_service.delete_multiple_photos_from_gcs(gcs_paths_to_delete)
            if not gcs_delete_success:
                 logger.error(f"Failed to delete one or more GCS photos for item {item_id}.")
                 raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to delete associated photos from storage.")
        except ConnectionError as e:
             logger.error(f"GCS connection error during photo deletion for item {item_id}: {e}", exc_info=True)
             raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Storage service unavailable.")
        except Exception as e:
             logger.error(f"Unexpected error deleting GCS photos for item {item_id}: {e}", exc_info=True)
             raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error during photo deletion.")

    # 3. Delete item from Firestore
    try:
        firestore_delete_success = await firestore_service.delete_item_and_photos(item_id)
        if not firestore_delete_success:
            logger.error(f"Firestore failed to delete item document {item_id}.")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to delete item metadata after deleting photos.")

        logger.info(f"Successfully deleted item {item_id} and associated photos.")
        return None # Return None for 204

    except ConnectionError as e:
         logger.error(f"Firestore connection error during item deletion for {item_id}: {e}", exc_info=True)
         raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Database service unavailable.")
    except HTTPException as http_exc:
         raise http_exc # Re-raise exceptions (e.g., from GCS step)
    except Exception as e:
        logger.error(f"Unexpected error deleting item {item_id} from Firestore: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to delete item metadata.")

