# services/firestore_service.py
import logging

# Import date, datetime, time, timezone
from datetime import datetime, timezone  # Ensure timezone is imported
from typing import List, Optional

from google.cloud import firestore
from google.cloud.firestore_v1.base_query import FieldFilter

# Attempt to import pytz for better timezone name handling, optional
try:
    import pytz
except ImportError:
    pytz = None
    logging.warning(
        "pytz library not found. Timezone name extraction might be "
        "limited to offset strings."
    )


from config import settings
from models import Photo, PhotoUpdate, PotteryItem, PotteryItemBase, PotteryItemCreate

logger = logging.getLogger(__name__)

# Lazy initialization - clients created on first use
_db = None
_items_collection = None
_initialization_attempted = False
_initialization_error = None


def _ensure_firestore_client():
    """Ensure Firestore client is initialized. Raises ConnectionError if failed."""
    global _db, _items_collection, _initialization_attempted, _initialization_error

    if _initialization_attempted and _initialization_error:
        raise ConnectionError(
            f"Firestore client failed to initialize: {_initialization_error}"
        )

    if _db is not None:
        return _db, _items_collection

    _initialization_attempted = True
    try:
        _db = firestore.AsyncClient(
            project=settings.gcp_project_id,
            database=settings.firestore_database_id,
        )
        _items_collection = _db.collection(settings.firestore_collection)
        logger.info(
            f"Firestore client initialized for project {settings.gcp_project_id}, "
            f"database '{settings.firestore_database_id}', "
            f"collection '{settings.firestore_collection}'"
        )
        return _db, _items_collection
    except Exception as e:
        _initialization_error = str(e)
        logger.error(f"Failed to initialize Firestore client: {e}", exc_info=True)
        raise ConnectionError(f"Firestore client initialization failed: {e}")


# --- Helper to extract timezone info ---
def get_timezone_identifier(dt: Optional[datetime]) -> Optional[str]:
    """Attempts to get a timezone identifier (like 'America/New_York' or
    offset) from a datetime object.
    """
    if dt and dt.tzinfo:
        tz_name = dt.tzname()
        if tz_name:
            # Basic check for simple offset names
            if tz_name in ["UTC", "GMT"] or any(c in tz_name for c in "+-"):
                offset_seconds = dt.tzinfo.utcoffset(dt).total_seconds()
                if offset_seconds == 0:
                    return "UTC"
                hours, rem = divmod(abs(offset_seconds), 3600)
                minutes, _ = divmod(rem, 60)
                sign = "+" if offset_seconds >= 0 else "-"
                return f"{sign}{int(hours):02d}:{int(minutes):02d}"
            else:  # Assume it's a proper name (e.g., from pytz)
                return tz_name
        else:  # Fallback to offset string if tzname() is None
            offset_seconds = dt.tzinfo.utcoffset(dt).total_seconds()
            if offset_seconds == 0:
                return "UTC"
            hours, rem = divmod(abs(offset_seconds), 3600)
            minutes, _ = divmod(rem, 60)
            sign = "+" if offset_seconds >= 0 else "-"
            return f"{sign}{int(hours):02d}:{int(minutes):02d}"
    return None


async def get_all_items(user_id: str = None) -> List[PotteryItem]:
    """
    Retrieves pottery items from Firestore.
    If user_id is provided, only returns items belonging to that user.
    If user_id is None, returns all items (admin functionality).
    """
    db, items_collection = _ensure_firestore_client()
    items = []
    try:
        # If user_id is provided, filter by user_id
        if user_id:
            query = items_collection.where(filter=FieldFilter("user_id", "==", user_id))
            stream = query.stream()
        else:
            # If no user_id, get all items (admin functionality)
            stream = items_collection.stream()

        async for doc in stream:
            item_data = doc.to_dict()
            if not item_data:  # Skip if data is somehow empty
                continue
            item_data["id"] = doc.id  # Add Firestore document ID

            # Ensure photos list exists and parse photo data
            item_data["photos"] = [Photo(**p) for p in item_data.get("photos", [])]
            # Firestore returns UTC datetime. Model expects datetime. No conversion
            # needed on read.
            items.append(PotteryItem(**item_data))

        if user_id:
            logger.info(
                f"Retrieved {len(items)} items for user {user_id} "
                f"from Firestore collection '{settings.firestore_collection}'."
            )
        else:
            logger.info(
                f"Retrieved {len(items)} items (all users) "
                f"from Firestore collection '{settings.firestore_collection}'."
            )
        return items
    except Exception as e:
        logger.error(f"Error retrieving items from Firestore: {e}", exc_info=True)
        raise


async def create_item(item_create: PotteryItemCreate, user_id: str) -> PotteryItem:
    """Creates a new pottery item in Firestore associated with the specified user."""
    db, items_collection = _ensure_firestore_client()
    item_data = {}
    try:
        doc_ref = items_collection.document()
        item_data = item_create.model_dump(exclude_unset=True)
        item_data["photos"] = []  # Initialize with empty photos list
        item_data["user_id"] = user_id  # Associate the item with the user

        created_dt = item_create.createdDateTime
        item_data["createdTimezone"] = get_timezone_identifier(created_dt)
        # Pass aware datetime directly to Firestore client
        item_data["createdDateTime"] = created_dt

        logger.debug(f"Attempting to save item data: {item_data}")
        await doc_ref.set(item_data)

        # Return the internal model representation
        new_item_data = item_data.copy()
        new_item = PotteryItem(id=doc_ref.id, **new_item_data)

        logger.info(
            f"Created item with ID: {new_item.id} for user {user_id} "
            f"in collection '{settings.firestore_collection}'."
        )
        return new_item
    except Exception:
        logger.error(
            f"Error creating item in Firestore. Data attempted: {item_data}",
            exc_info=True,
        )
        raise


async def get_item_by_id(item_id: str, user_id: str = None) -> Optional[PotteryItem]:
    """
    Retrieves a single pottery item by its Firestore document ID.
    If user_id is provided, only returns the item if it belongs to that user.
    If user_id is None, returns the item regardless of ownership (admin functionality).
    """
    db, items_collection = _ensure_firestore_client()
    try:
        doc_ref = items_collection.document(item_id)
        doc = await doc_ref.get()
        if doc.exists:
            item_data = doc.to_dict()
            if not item_data:
                logger.warning(f"Item {item_id} exists but has empty data.")
                return None

            # Check if the item belongs to the specified user
            if user_id and item_data.get("user_id") != user_id:
                logger.warning(
                    f"User {user_id} attempted to access item {item_id} "
                    f"which belongs to user {item_data.get('user_id')}."
                )
                return None

            item_data["id"] = doc.id
            item_data["photos"] = [Photo(**p) for p in item_data.get("photos", [])]
            # Firestore returns UTC datetime. Model expects datetime. No conversion
            # needed on read.
            logger.debug(f"Retrieved item with ID: {item_id}")
            return PotteryItem(**item_data)
        else:
            logger.warning(
                f"Item with ID {item_id} not found in Firestore "
                f"collection '{settings.firestore_collection}'."
            )
            return None
    except Exception as e:
        logger.error(
            f"Error retrieving item {item_id} from Firestore: {e}", exc_info=True
        )
        raise


async def update_item_metadata(
    item_id: str, item_update: PotteryItemBase, user_id: str = None
) -> Optional[PotteryItem]:
    """
    Updates metadata fields of an existing pottery item in Firestore.
    If user_id is provided, only updates the item if it belongs to that user.
    If user_id is None, updates the item regardless of ownership (admin functionality).
    """
    db, items_collection = _ensure_firestore_client()
    update_data = {}
    try:
        doc_ref = items_collection.document(item_id)
        doc_snapshot = await doc_ref.get()
        if not doc_snapshot.exists:
            logger.warning(f"Attempted to update non-existent item with ID: {item_id}")
            return None

        # Check if the item belongs to the specified user
        item_data = doc_snapshot.to_dict()
        if user_id and item_data.get("user_id") != user_id:
            logger.warning(
                f"User {user_id} attempted to update item {item_id} "
                f"which belongs to user {item_data.get('user_id')}."
            )
            return None

        update_data = item_update.model_dump(exclude_unset=True)

        if "createdDateTime" in update_data:
            created_dt = item_update.createdDateTime
            update_data["createdTimezone"] = get_timezone_identifier(created_dt)
            update_data["createdDateTime"] = created_dt  # Pass aware datetime
        else:
            update_data.pop("createdTimezone", None)

        # Set updatedDateTime to current UTC time on every update
        update_data["updatedDateTime"] = datetime.now(timezone.utc)

        logger.debug(f"Attempting to update item {item_id} with data: {update_data}")
        await doc_ref.update(update_data)

        # Pass the user_id to get_item_by_id to ensure ownership check is consistent
        updated_item = await get_item_by_id(item_id, user_id)
        if updated_item:
            logger.info(f"Updated metadata for item with ID: {item_id}")
        return updated_item

    except Exception:
        logger.error(
            f"Error updating item {item_id} in Firestore. Data attempted: "
            f"{update_data}",
            exc_info=True,
        )
        raise


async def delete_item_and_photos(item_id: str, user_id: str = None) -> bool:
    """
    Deletes a pottery item document from Firestore.
    If user_id is provided, only deletes the item if it belongs to that user.
    If user_id is None, deletes the item regardless of ownership (admin
    functionality).
    Returns True if deleted or not found, False on error.
    Note: Associated GCS photos must be deleted separately by the caller
    (usually via gcs_service).
    """
    db, items_collection = _ensure_firestore_client()
    try:
        doc_ref = items_collection.document(item_id)

        # Check if the item belongs to the specified user
        if user_id:
            doc_snapshot = await doc_ref.get()
            if doc_snapshot.exists:
                item_data = doc_snapshot.to_dict()
                if item_data and item_data.get("user_id") != user_id:
                    logger.warning(
                        f"User {user_id} attempted to delete item {item_id} which "
                        f"belongs to user {item_data.get('user_id')}."
                    )
                    return False

        await doc_ref.delete()
        logger.info(
            f"Deleted item document with ID: {item_id} from collection "
            f"'{settings.firestore_collection}' (or it didn't exist)."
        )
        return True
    except Exception as e:
        logger.error(
            f"Error deleting item {item_id} from Firestore: {e}", exc_info=True
        )
        return False  # Indicate failure


# --- Photo Specific Operations ---


async def add_photo_to_item(
    item_id: str, photo: Photo, user_id: str = None
) -> Optional[PotteryItem]:
    """
    Adds photo metadata to an item's 'photos' array in Firestore.
    If user_id is provided, only adds the photo if the item belongs to that user.
    If user_id is None, adds the photo regardless of ownership (admin functionality).
    """
    db, items_collection = _ensure_firestore_client()
    try:
        # Check if the item exists and belongs to the specified user
        if user_id:
            item = await get_item_by_id(item_id, user_id)
            if not item:
                logger.warning(
                    f"User {user_id} attempted to add photo to item {item_id} which "
                    f"either doesn't exist or doesn't belong to them."
                )
                return None

        doc_ref = items_collection.document(item_id)
        photo_data = photo.model_dump()

        # Ensure uploadedAt is aware UTC and set timezone identifier
        # The model default factory now creates aware UTC time
        if isinstance(photo_data.get("uploadedAt"), datetime):
            if photo_data["uploadedAt"].tzinfo is None:
                # Should not happen with new default factory, but handle defensively
                logger.warning(
                    f"uploadedAt for photo {photo.id} was naive, forcing UTC."
                )
                photo_data["uploadedAt"] = photo_data["uploadedAt"].replace(
                    tzinfo=timezone.utc
                )
            photo_data["uploadedTimezone"] = "UTC"  # Explicitly set timezone for upload
        else:
            logger.warning(
                f"uploadedAt for photo {photo.id} is not datetime: "
                f"{photo_data.get('uploadedAt')}. Setting to now(timezone.utc)."
            )
            photo_data["uploadedAt"] = datetime.now(timezone.utc)
            photo_data["uploadedTimezone"] = "UTC"

        logger.debug(f"Adding photo data to item {item_id}: {photo_data}")
        await doc_ref.update(
            {
                "photos": firestore.ArrayUnion([photo_data]),
                "updatedDateTime": datetime.now(timezone.utc),
            }
        )

        # Pass the user_id to get_item_by_id to ensure ownership check is consistent
        updated_item = await get_item_by_id(item_id, user_id)
        if updated_item:
            logger.info(f"Added photo {photo.id} to item {item_id}")
            return updated_item
        else:
            logger.error(
                f"Failed to retrieve item {item_id} after adding photo {photo.id}"
            )
            return None
    except Exception as e:
        logger.error(
            f"Error adding photo metadata for item {item_id}: {e}", exc_info=True
        )
        if "NotFound" in str(e) or "NOT_FOUND" in str(e):
            logger.warning(
                f"Item {item_id} not found when trying to add photo {photo.id}."
            )
            return None
        raise


async def remove_photo_from_item(
    item_id: str, photo_id: str, user_id: str = None
) -> Optional[PotteryItem]:
    """
    Removes photo metadata from an item's 'photos' array in Firestore.
    If user_id is provided, only removes the photo if the item belongs to that user.
    If user_id is None, removes the photo regardless of ownership (admin functionality).

    Uses array replacement instead of ArrayRemove to avoid datetime matching issues.
    """
    db, items_collection = _ensure_firestore_client()
    try:
        # Check if the item exists and belongs to the specified user
        if user_id:
            item = await get_item_by_id(item_id, user_id)
            if not item:
                logger.warning(
                    f"User {user_id} attempted to remove photo from item {item_id} "
                    f"which either doesn't exist or doesn't belong to them."
                )
                return None

        doc_ref = items_collection.document(item_id)
        # Get current raw data
        doc_snapshot = await doc_ref.get()
        if not doc_snapshot.exists:
            logger.warning(f"Cannot remove photo {photo_id}, item {item_id} not found.")
            return None
        current_data = doc_snapshot.to_dict()
        current_photos = current_data.get("photos", []) if current_data else []

        # Filter out the photo by ID (more reliable than ArrayRemove with datetimes)
        photo_found = False
        filtered_photos = []
        for p_dict in current_photos:
            if isinstance(p_dict, dict) and p_dict.get("id") == photo_id:
                photo_found = True
                logger.debug(f"Found and removing photo {photo_id}")
                # Skip this photo (don't add to filtered list)
                continue
            filtered_photos.append(p_dict)

        if not photo_found:
            logger.warning(
                f"Photo {photo_id} not found within item {item_id}. "
                f"No update performed."
            )
            # Return item as-is
            return await get_item_by_id(item_id, user_id)

        # Replace entire photos array with filtered version
        # This is more reliable than ArrayRemove for datetime fields
        logger.debug(
            f"Replacing photos array: {len(current_photos)} -> "
            f"{len(filtered_photos)} photos"
        )
        await doc_ref.update(
            {
                "photos": filtered_photos,
                "updatedDateTime": datetime.now(timezone.utc),
            }
        )

        # Read back and verify removal
        updated_item = await get_item_by_id(item_id, user_id)
        if updated_item:
            logger.info(f"Removed photo {photo_id} from item {item_id}")
            if any(p.id == photo_id for p in updated_item.photos):
                logger.error(
                    f"Photo {photo_id} still present in item {item_id} "
                    f"after removal attempt!"
                )
            return updated_item
        else:
            logger.error(
                f"Failed to retrieve item {item_id} after removing photo {photo_id}"
            )
            return None
    except Exception as e:
        logger.error(
            f"Error removing photo {photo_id} metadata for item {item_id}: {e}",
            exc_info=True,
        )
        raise


async def update_photo_details_in_item(
    item_id: str, photo_id: str, photo_update: PhotoUpdate, user_id: str = None
) -> Optional[Photo]:
    """
    Updates metadata (stage, note) of a specific photo within an item's 'photos' array.
    If user_id is provided, only updates the photo if the item belongs to that user.
    If user_id is None, updates the photo regardless of ownership (admin functionality).
    """
    db, items_collection = _ensure_firestore_client()
    try:
        # Check if the item exists and belongs to the specified user
        item = await get_item_by_id(item_id, user_id)
        if not item:
            if user_id:
                logger.warning(
                    f"User {user_id} attempted to update photo in item {item_id} which "
                    f"either doesn't exist or doesn't belong to them."
                )
            else:
                logger.warning(
                    f"Cannot update photo {photo_id}, item {item_id} not found."
                )
            return None  # Item not found or not owned by user

        doc_ref = items_collection.document(item_id)
        updated_photos_list = []
        target_photo_model: Optional[Photo] = None
        photo_found = False

        for p in item.photos:
            photo_dict = (
                p.model_dump()
            )  # Get dict representation from current model state
            if p.id == photo_id:
                photo_found = True
                update_data = photo_update.model_dump(exclude_unset=True)
                photo_dict.update(update_data)  # Apply changes to the dict
                # Re-validate with Photo model in case update data is invalid? Optional.
                target_photo_model = Photo(
                    **photo_dict
                )  # Create model for return value
            updated_photos_list.append(
                photo_dict
            )  # Add potentially updated dict to list

        if not photo_found:
            logger.warning(
                f"Photo {photo_id} not found within item {item_id}. "
                f"No update performed."
            )
            return None

        # Overwrite the entire photos array with the updated list
        # Firestore client handles datetime serialization
        await doc_ref.update(
            {
                "photos": updated_photos_list,
                "updatedDateTime": datetime.now(timezone.utc),
            }
        )

        logger.info(f"Updated details for photo {photo_id} in item {item_id}")
        # Return the updated Photo model (validated earlier)
        return target_photo_model

    except Exception as e:
        logger.error(
            f"Error updating photo {photo_id} details for item {item_id}: {e}",
            exc_info=True,
        )
        raise


async def set_primary_photo(
    item_id: str, photo_id: str, user_id: str = None
) -> Optional[Photo]:
    """
    Sets a photo as the primary photo for an item.
    Ensures only one photo is marked as primary by setting isPrimary=True for the
    target photo and isPrimary=False for all other photos in the item.
    If user_id is provided, only updates the photo if the item belongs to that user.
    If user_id is None, updates the photo regardless of ownership (admin functionality).
    """
    db, items_collection = _ensure_firestore_client()
    try:
        # Opening move: verify item exists and user has access
        item = await get_item_by_id(item_id, user_id)
        if not item:
            if user_id:
                logger.warning(
                    f"User {user_id} attempted to set primary photo in item {item_id} "
                    f"which either doesn't exist or doesn't belong to them."
                )
            else:
                logger.warning(
                    f"Cannot set primary photo {photo_id}, item {item_id} not found."
                )
            return None

        doc_ref = items_collection.document(item_id)
        updated_photos_list = []
        target_photo_model: Optional[Photo] = None
        photo_found = False

        # Main play: loop through photos and set isPrimary appropriately
        for p in item.photos:
            photo_dict = p.model_dump()
            if p.id == photo_id:
                # Victory moment: mark this one as primary
                photo_found = True
                photo_dict["isPrimary"] = True
                target_photo_model = Photo(**photo_dict)
                logger.debug(f"Setting photo {photo_id} as primary in item {item_id}")
            else:
                # Supporting cast: ensure all others are not primary
                photo_dict["isPrimary"] = False
            updated_photos_list.append(photo_dict)

        if not photo_found:
            logger.warning(
                f"Photo {photo_id} not found within item {item_id}. "
                f"Cannot set as primary."
            )
            return None

        # Final whistle: persist the changes
        await doc_ref.update(
            {
                "photos": updated_photos_list,
                "updatedDateTime": datetime.now(timezone.utc),
            }
        )

        logger.info(f"Set photo {photo_id} as primary for item {item_id}")
        return target_photo_model

    except Exception as e:
        logger.error(
            f"Error setting primary photo {photo_id} for item {item_id}: {e}",
            exc_info=True,
        )
        raise
