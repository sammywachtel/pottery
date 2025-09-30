# tests/test_photos_router.py
import io  # For creating dummy file content
import os

# Assuming your models are importable
# Add project root to path if running tests directly and imports fail
import sys
import uuid
from datetime import datetime, timezone
from unittest.mock import ANY, AsyncMock

import pytest

# *** UPDATED: Import HTTPException ***
from fastapi import status
from fastapi.testclient import TestClient

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

from models import Photo, PhotoUpdate, PotteryItem  # noqa: E402

# Re-use sample data from items test or define new ones
TEST_ITEM_ID_1 = str(uuid.uuid4())
TEST_PHOTO_ID_NEW = str(uuid.uuid4())  # For new upload
EXISTING_PHOTO_ID = str(uuid.uuid4())
EXISTING_GCS_PATH = f"items/{TEST_ITEM_ID_1}/{EXISTING_PHOTO_ID}.png"

NOW_UTC = datetime.now(timezone.utc)

# Sample Photo object (internal representation)
existing_photo_internal = Photo(
    id=EXISTING_PHOTO_ID,
    gcsPath=EXISTING_GCS_PATH,
    stage="Greenware",
    fileName="existing.png",
    uploadedAt=NOW_UTC,  # Aware UTC
    uploadedTimezone="UTC",
)

# Sample PotteryItem with an existing photo
sample_item_with_photo = PotteryItem(
    id=TEST_ITEM_ID_1,
    name="Item With Photo",
    clayType="Stoneware",
    createdDateTime=NOW_UTC,
    createdTimezone="UTC",
    location="Studio",
    photos=[existing_photo_internal],  # Include existing photo
    user_id="test-firebase-uid-123",
)

# Sample item with no photos (for upload test)
sample_item_no_photos = PotteryItem(
    id=TEST_ITEM_ID_1,
    name="Item No Photo",
    clayType="Stoneware",
    createdDateTime=NOW_UTC,
    createdTimezone="UTC",
    location="Studio",
    photos=[],
    user_id="test-firebase-uid-123",
)


# --- POST /api/items/{item_id}/photos ---


@pytest.mark.asyncio
async def test_upload_photo_success(client: TestClient, mocker, auth_headers):
    """Test POST /api/items/{item_id}/photos successfully."""
    # 1. Mock underlying service call used by the dependency
    mock_get_item_svc = mocker.patch(
        "services.firestore_service.get_item_by_id", new_callable=AsyncMock
    )
    mock_get_item_svc.return_value = sample_item_no_photos  # Item exists

    # 2. Mock GCS upload
    mock_gcs_upload = mocker.patch(
        "services.gcs_service.upload_photo_to_gcs", new_callable=AsyncMock
    )
    expected_gcs_path = f"items/{TEST_ITEM_ID_1}/{TEST_PHOTO_ID_NEW}.jpg"
    mock_uuid = mocker.patch("uuid.uuid4", return_value=uuid.UUID(TEST_PHOTO_ID_NEW))
    mock_gcs_upload.return_value = expected_gcs_path

    # 3. Mock Firestore add photo metadata
    mock_fs_add_photo = mocker.patch(
        "services.firestore_service.add_photo_to_item", new_callable=AsyncMock
    )
    # Simulate the service returning the updated item with the new photo
    new_photo_internal = Photo(
        id=TEST_PHOTO_ID_NEW,
        gcsPath=expected_gcs_path,
        stage="Greenware",
        fileName="dummy.jpg",
        imageNote="Test upload",
        uploadedAt=NOW_UTC,  # Should match mocked datetime.now
        uploadedTimezone="UTC",
    )
    updated_item_internal = sample_item_no_photos.model_copy(deep=True)
    updated_item_internal.photos.append(new_photo_internal)
    mock_fs_add_photo.return_value = updated_item_internal

    # 4. Mock GCS generate signed URL for the response
    mock_generate_url = mocker.patch(
        "services.gcs_service.generate_signed_url", new_callable=AsyncMock
    )
    mock_generate_url.return_value = (
        f"https://fake-signed-url.com/{TEST_PHOTO_ID_NEW}.jpg"
    )

    # 5. Prepare form data and file
    file_content = b"dummy image data"
    dummy_file = io.BytesIO(file_content)
    form_data = {"photo_stage": "Greenware", "photo_note": "Test upload"}
    files = {"file": ("dummy.jpg", dummy_file, "image/jpeg")}

    # Patch datetime.now to control uploadedAt timestamp consistency in test
    mock_dt = mocker.patch("datetime.datetime", wraps=datetime)
    mock_dt.now.return_value = NOW_UTC  # Control what now(timezone.utc) returns

    response = client.post(
        f"/api/items/{TEST_ITEM_ID_1}/photos",
        data=form_data,
        files=files,
        headers=auth_headers,
    )

    # Assertions
    assert response.status_code == status.HTTP_201_CREATED
    json_response = response.json()
    assert json_response["id"] == TEST_PHOTO_ID_NEW
    assert json_response["stage"] == form_data["photo_stage"]
    assert json_response["signedUrl"] == mock_generate_url.return_value
    assert json_response["uploadedTimezone"] == "UTC"

    # Compare datetime values, not strings
    response_dt_str = json_response["uploadedAt"]
    response_dt = datetime.fromisoformat(response_dt_str.replace("Z", "+00:00"))
    # Compare against the controlled NOW_UTC used in the mock
    assert response_dt == NOW_UTC

    mock_get_item_svc.assert_awaited_once_with(
        TEST_ITEM_ID_1, user_id="test-firebase-uid-123"
    )  # Check service mock
    mock_gcs_upload.assert_awaited_once_with(
        item_id=TEST_ITEM_ID_1,
        photo_id=TEST_PHOTO_ID_NEW,
        file_content=file_content,
        content_type="image/jpeg",
        original_filename="dummy.jpg",
    )
    mock_fs_add_photo.assert_awaited_once()
    call_args, call_kwargs = mock_fs_add_photo.call_args
    assert call_args[0] == TEST_ITEM_ID_1
    added_photo_arg = call_args[1]
    assert isinstance(added_photo_arg, Photo)
    assert added_photo_arg.id == TEST_PHOTO_ID_NEW
    assert (
        call_kwargs["user_id"] == "test-firebase-uid-123"
    )  # Check user_id is passed correctly

    mock_generate_url.assert_awaited_once_with(expected_gcs_path)
    mock_uuid.assert_called_once()


@pytest.mark.asyncio
async def test_upload_photo_item_not_found(client: TestClient, mocker, auth_headers):
    """Test POST /photos when the item doesn't exist."""
    # *** FIX: Mock the underlying service call to return None ***
    mock_get_item_svc = mocker.patch(
        "services.firestore_service.get_item_by_id", new_callable=AsyncMock
    )
    mock_get_item_svc.return_value = None  # Simulate item not found in DB

    dummy_file = io.BytesIO(b"data")
    files = {"file": ("dummy.jpg", dummy_file, "image/jpeg")}
    form_data = {"photo_stage": "Greenware"}

    response = client.post(
        f"/api/items/{TEST_ITEM_ID_1}/photos",
        data=form_data,
        files=files,
        headers=auth_headers,
    )

    # Assert: The _get_item_or_404 dependency should now run, get None, and raise 404
    assert response.status_code == status.HTTP_404_NOT_FOUND
    assert (
        response.json()["detail"]
        == f"Pottery item with ID '{TEST_ITEM_ID_1}' not found."
    )
    mock_get_item_svc.assert_awaited_once_with(
        TEST_ITEM_ID_1, user_id="test-firebase-uid-123"
    )


@pytest.mark.asyncio
async def test_upload_photo_validation_error_missing_file(
    client: TestClient, mocker, auth_headers
):
    """Test POST /photos with missing file."""
    # Mock dependency service call to allow request to reach validation stage
    mock_get_item_svc = mocker.patch(
        "services.firestore_service.get_item_by_id", new_callable=AsyncMock
    )
    mock_get_item_svc.return_value = sample_item_no_photos

    form_data = {"photo_stage": "Greenware"}
    response = client.post(
        f"/api/items/{TEST_ITEM_ID_1}/photos", data=form_data, headers=auth_headers
    )  # No files
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.asyncio
async def test_upload_photo_validation_error_missing_stage(
    client: TestClient, mocker, auth_headers
):
    """Test POST /photos with missing stage."""
    mock_get_item_svc = mocker.patch(
        "services.firestore_service.get_item_by_id", new_callable=AsyncMock
    )
    mock_get_item_svc.return_value = sample_item_no_photos

    dummy_file = io.BytesIO(b"data")
    files = {"file": ("dummy.jpg", dummy_file, "image/jpeg")}
    response = client.post(
        f"/api/items/{TEST_ITEM_ID_1}/photos", files=files, headers=auth_headers
    )  # No data
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.asyncio
async def test_upload_photo_gcs_error(client: TestClient, mocker, auth_headers):
    """Test POST /photos when GCS upload fails."""
    mock_get_item_svc = mocker.patch(
        "services.firestore_service.get_item_by_id", new_callable=AsyncMock
    )
    mock_get_item_svc.return_value = sample_item_no_photos

    mock_gcs_upload = mocker.patch(
        "services.gcs_service.upload_photo_to_gcs", new_callable=AsyncMock
    )
    mock_gcs_upload.side_effect = Exception("GCS bucket permission denied")

    _ = mocker.patch("uuid.uuid4", return_value=uuid.UUID(TEST_PHOTO_ID_NEW))

    dummy_file = io.BytesIO(b"data")
    files = {"file": ("dummy.jpg", dummy_file, "image/jpeg")}
    form_data = {"photo_stage": "Greenware"}

    response = client.post(
        f"/api/items/{TEST_ITEM_ID_1}/photos",
        data=form_data,
        files=files,
        headers=auth_headers,
    )

    assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    # Check detail from the specific handler in upload_photo endpoint
    assert response.json()["detail"] == "Failed to upload photo to storage."
    mock_gcs_upload.assert_awaited_once()


@pytest.mark.asyncio
async def test_upload_photo_firestore_error(client: TestClient, mocker, auth_headers):
    """Test POST /photos when adding metadata to Firestore fails."""
    mock_get_item_svc = mocker.patch(
        "services.firestore_service.get_item_by_id", new_callable=AsyncMock
    )
    mock_get_item_svc.return_value = sample_item_no_photos

    mock_gcs_upload = mocker.patch(
        "services.gcs_service.upload_photo_to_gcs", new_callable=AsyncMock
    )
    expected_gcs_path = f"items/{TEST_ITEM_ID_1}/{TEST_PHOTO_ID_NEW}.jpg"
    mock_gcs_upload.return_value = expected_gcs_path

    mock_fs_add_photo = mocker.patch(
        "services.firestore_service.add_photo_to_item", new_callable=AsyncMock
    )
    mock_fs_add_photo.side_effect = Exception("Firestore array update failed")

    mock_gcs_delete = mocker.patch(
        "services.gcs_service.delete_photo_from_gcs", new_callable=AsyncMock
    )
    mock_gcs_delete.return_value = True

    _ = mocker.patch("uuid.uuid4", return_value=uuid.UUID(TEST_PHOTO_ID_NEW))
    mock_dt = mocker.patch("datetime.datetime", wraps=datetime)
    mock_dt.now.return_value = NOW_UTC

    dummy_file = io.BytesIO(b"data")
    files = {"file": ("dummy.jpg", dummy_file, "image/jpeg")}
    form_data = {"photo_stage": "Greenware"}

    response = client.post(
        f"/api/items/{TEST_ITEM_ID_1}/photos",
        data=form_data,
        files=files,
        headers=auth_headers,
    )

    assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    # Check detail from the specific handler in upload_photo endpoint
    assert response.json()["detail"] == "Failed to update item with photo metadata."
    mock_fs_add_photo.assert_awaited_once()
    mock_gcs_delete.assert_awaited_once_with(expected_gcs_path)


# --- DELETE /api/items/{item_id}/photos/{photo_id} ---


@pytest.mark.asyncio
async def test_delete_photo_success(client: TestClient, mocker, auth_headers):
    """Test DELETE /photos/{photo_id} successfully."""
    mock_get_item_svc = mocker.patch(
        "services.firestore_service.get_item_by_id", new_callable=AsyncMock
    )
    mock_get_item_svc.return_value = sample_item_with_photo  # Item exists with photo

    mock_gcs_delete = mocker.patch(
        "services.gcs_service.delete_photo_from_gcs", new_callable=AsyncMock
    )
    mock_gcs_delete.return_value = True

    mock_fs_remove_photo = mocker.patch(
        "services.firestore_service.remove_photo_from_item", new_callable=AsyncMock
    )
    updated_item_internal = sample_item_with_photo.model_copy(deep=True)
    updated_item_internal.photos = []
    mock_fs_remove_photo.return_value = updated_item_internal

    response = client.delete(
        f"/api/items/{TEST_ITEM_ID_1}/photos/{EXISTING_PHOTO_ID}", headers=auth_headers
    )

    assert response.status_code == status.HTTP_204_NO_CONTENT
    mock_get_item_svc.assert_awaited_once_with(
        TEST_ITEM_ID_1, user_id="test-firebase-uid-123"
    )  # Check service mock
    mock_gcs_delete.assert_awaited_once_with(EXISTING_GCS_PATH)
    mock_fs_remove_photo.assert_awaited_once_with(
        TEST_ITEM_ID_1, EXISTING_PHOTO_ID, user_id="test-firebase-uid-123"
    )


@pytest.mark.asyncio
async def test_delete_photo_item_not_found(client: TestClient, mocker, auth_headers):
    """Test DELETE /photos/{photo_id} when item not found."""
    # *** FIX: Mock the underlying service call to return None ***
    mock_get_item_svc = mocker.patch(
        "services.firestore_service.get_item_by_id", new_callable=AsyncMock
    )
    mock_get_item_svc.return_value = None  # Simulate item not found in DB

    response = client.delete(
        f"/api/items/{TEST_ITEM_ID_1}/photos/{EXISTING_PHOTO_ID}", headers=auth_headers
    )

    # Assert: The _get_item_or_404 dependency should now run, get None, and raise 404
    assert response.status_code == status.HTTP_404_NOT_FOUND
    assert (
        response.json()["detail"]
        == f"Pottery item with ID '{TEST_ITEM_ID_1}' not found."
    )
    mock_get_item_svc.assert_awaited_once_with(
        TEST_ITEM_ID_1, user_id="test-firebase-uid-123"
    )


@pytest.mark.asyncio
async def test_delete_photo_photo_not_found_in_item(
    client: TestClient, mocker, auth_headers
):
    """Test DELETE /photos/{photo_id} when item exists but photo doesn't."""
    # Simulate item returned by dependency service call, but photo isn't in it
    item_without_target_photo = sample_item_with_photo.model_copy(deep=True)
    item_without_target_photo.photos = [
        Photo(
            id="other_photo",
            gcsPath="other/path",
            stage="Glazed",
            uploadedAt=NOW_UTC,
            uploadedTimezone="UTC",
        )
    ]
    mock_get_item_svc = mocker.patch(
        "services.firestore_service.get_item_by_id", new_callable=AsyncMock
    )
    mock_get_item_svc.return_value = item_without_target_photo

    # Mock services that shouldn't be called if photo isn't found by router helper
    mock_gcs_delete = mocker.patch(
        "services.gcs_service.delete_photo_from_gcs", new_callable=AsyncMock
    )
    mock_fs_remove_photo = mocker.patch(
        "services.firestore_service.remove_photo_from_item", new_callable=AsyncMock
    )

    response = client.delete(
        f"/api/items/{TEST_ITEM_ID_1}/photos/{EXISTING_PHOTO_ID}", headers=auth_headers
    )

    assert response.status_code == status.HTTP_404_NOT_FOUND
    # Detail comes from _get_photo_from_item_or_404 helper in photos router
    assert (
        response.json()["detail"]
        == f"Photo with ID '{EXISTING_PHOTO_ID}' not found in item '{TEST_ITEM_ID_1}'."
    )
    mock_get_item_svc.assert_awaited_once_with(
        TEST_ITEM_ID_1, user_id="test-firebase-uid-123"
    )
    mock_gcs_delete.assert_not_awaited()
    mock_fs_remove_photo.assert_not_awaited()


@pytest.mark.asyncio
async def test_delete_photo_gcs_error(client: TestClient, mocker, auth_headers):
    """Test DELETE /photos/{photo_id} when GCS delete fails."""
    mock_get_item_svc = mocker.patch(
        "services.firestore_service.get_item_by_id", new_callable=AsyncMock
    )
    mock_get_item_svc.return_value = sample_item_with_photo

    mock_gcs_delete = mocker.patch(
        "services.gcs_service.delete_photo_from_gcs", new_callable=AsyncMock
    )
    # Simulate GCS failure by raising an exception
    mock_gcs_delete.side_effect = Exception("GCS Network Error")

    mock_fs_remove_photo = mocker.patch(
        "services.firestore_service.remove_photo_from_item", new_callable=AsyncMock
    )

    response = client.delete(
        f"/api/items/{TEST_ITEM_ID_1}/photos/{EXISTING_PHOTO_ID}", headers=auth_headers
    )

    assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    # *** FIX: Assert correct error detail from router's except Exception block ***
    assert response.json()["detail"] == "Error during photo deletion from storage."
    mock_get_item_svc.assert_awaited_once_with(
        TEST_ITEM_ID_1, user_id="test-firebase-uid-123"
    )
    mock_gcs_delete.assert_awaited_once_with(EXISTING_GCS_PATH)
    mock_fs_remove_photo.assert_not_awaited()  # Should not be called if GCS fails


@pytest.mark.asyncio
async def test_delete_photo_firestore_error(client: TestClient, mocker, auth_headers):
    """Test DELETE /photos/{photo_id} when Firestore remove fails."""
    mock_get_item_svc = mocker.patch(
        "services.firestore_service.get_item_by_id", new_callable=AsyncMock
    )
    mock_get_item_svc.return_value = sample_item_with_photo

    mock_gcs_delete = mocker.patch(
        "services.gcs_service.delete_photo_from_gcs", new_callable=AsyncMock
    )
    mock_gcs_delete.return_value = True

    mock_fs_remove_photo = mocker.patch(
        "services.firestore_service.remove_photo_from_item", new_callable=AsyncMock
    )
    mock_fs_remove_photo.side_effect = Exception("Firestore array remove failed")

    response = client.delete(
        f"/api/items/{TEST_ITEM_ID_1}/photos/{EXISTING_PHOTO_ID}", headers=auth_headers
    )

    assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    # Check specific detail from the handler in delete_photo endpoint
    assert response.json()["detail"] == "Failed to remove photo metadata from item."
    mock_get_item_svc.assert_awaited_once_with(
        TEST_ITEM_ID_1, user_id="test-firebase-uid-123"
    )
    mock_gcs_delete.assert_awaited_once_with(EXISTING_GCS_PATH)
    mock_fs_remove_photo.assert_awaited_once_with(
        TEST_ITEM_ID_1, EXISTING_PHOTO_ID, user_id="test-firebase-uid-123"
    )


# --- PUT /api/items/{item_id}/photos/{photo_id} ---
photo_update_payload = {"stage": "Glazed", "imageNote": "Final photo"}


@pytest.mark.asyncio
async def test_update_photo_details_success(
    client: TestClient, mocker, auth_headers, common_headers
):
    """Test PUT /photos/{photo_id} successfully."""
    mock_get_item_svc = mocker.patch(
        "services.firestore_service.get_item_by_id", new_callable=AsyncMock
    )
    mock_get_item_svc.return_value = sample_item_with_photo  # Item exists with photo

    mock_update_details = mocker.patch(
        "services.firestore_service.update_photo_details_in_item",
        new_callable=AsyncMock,
    )
    updated_photo_internal = existing_photo_internal.model_copy(
        update=photo_update_payload
    )
    mock_update_details.return_value = updated_photo_internal

    mock_generate_url = mocker.patch(
        "services.gcs_service.generate_signed_url", new_callable=AsyncMock
    )
    mock_generate_url.return_value = (
        f"https://fake-signed-url.com/{EXISTING_PHOTO_ID}.png"
    )

    headers = {**common_headers, **auth_headers}
    response = client.put(
        f"/api/items/{TEST_ITEM_ID_1}/photos/{EXISTING_PHOTO_ID}",
        json=photo_update_payload,
        headers=headers,
    )

    assert response.status_code == status.HTTP_200_OK
    json_response = response.json()
    assert json_response["id"] == EXISTING_PHOTO_ID
    assert json_response["stage"] == photo_update_payload["stage"]
    assert json_response["signedUrl"] is not None

    mock_get_item_svc.assert_awaited_once_with(
        TEST_ITEM_ID_1, user_id="test-firebase-uid-123"
    )  # Check service mock
    mock_update_details.assert_awaited_once()
    call_args, call_kwargs = mock_update_details.call_args
    assert call_args[0] == TEST_ITEM_ID_1
    assert call_args[1] == EXISTING_PHOTO_ID
    assert isinstance(call_args[2], PhotoUpdate)
    assert call_args[2].stage == photo_update_payload["stage"]
    assert (
        call_kwargs["user_id"] == "test-firebase-uid-123"
    )  # Check user_id is passed correctly

    mock_generate_url.assert_awaited_once_with(EXISTING_GCS_PATH)


@pytest.mark.asyncio
async def test_update_photo_details_item_not_found(
    client: TestClient, mocker, auth_headers, common_headers
):
    """Test PUT /photos/{photo_id} when item not found."""
    # *** FIX: Mock the underlying service call to return None ***
    mock_get_item_svc = mocker.patch(
        "services.firestore_service.get_item_by_id", new_callable=AsyncMock
    )
    mock_get_item_svc.return_value = None  # Simulate item not found in DB

    headers = {**common_headers, **auth_headers}
    response = client.put(
        f"/api/items/{TEST_ITEM_ID_1}/photos/{EXISTING_PHOTO_ID}",
        json=photo_update_payload,
        headers=headers,
    )

    # Assert: The _get_item_or_404 dependency should now run, get None, and raise 404
    assert response.status_code == status.HTTP_404_NOT_FOUND
    assert (
        response.json()["detail"]
        == f"Pottery item with ID '{TEST_ITEM_ID_1}' not found."
    )
    mock_get_item_svc.assert_awaited_once_with(
        TEST_ITEM_ID_1, user_id="test-firebase-uid-123"
    )


@pytest.mark.asyncio
async def test_update_photo_details_photo_not_found(
    client: TestClient, mocker, auth_headers, common_headers
):
    """Test PUT /photos/{photo_id} when photo not found in item."""
    mock_get_item_svc = mocker.patch(
        "services.firestore_service.get_item_by_id", new_callable=AsyncMock
    )
    mock_get_item_svc.return_value = sample_item_with_photo  # Item exists

    mock_update_details = mocker.patch(
        "services.firestore_service.update_photo_details_in_item",
        new_callable=AsyncMock,
    )
    mock_update_details.return_value = (
        None  # Simulate service returning None for photo not found
    )

    headers = {**common_headers, **auth_headers}
    response = client.put(
        f"/api/items/{TEST_ITEM_ID_1}/photos/{EXISTING_PHOTO_ID}",
        json=photo_update_payload,
        headers=headers,
    )

    assert response.status_code == status.HTTP_404_NOT_FOUND
    # Detail comes from the handler in update_photo_details endpoint
    assert (
        response.json()["detail"]
        == f"Photo with ID '{EXISTING_PHOTO_ID}' not found in item '{TEST_ITEM_ID_1}'."
    )
    mock_get_item_svc.assert_awaited_once_with(
        TEST_ITEM_ID_1, user_id="test-firebase-uid-123"
    )
    mock_update_details.assert_awaited_once_with(
        TEST_ITEM_ID_1, EXISTING_PHOTO_ID, ANY, user_id="test-firebase-uid-123"
    )


@pytest.mark.asyncio
async def test_update_photo_details_validation_error(
    client: TestClient, mocker, auth_headers, common_headers
):
    """Test PUT /photos/{photo_id} with invalid payload type."""
    mock_get_item_svc = mocker.patch(
        "services.firestore_service.get_item_by_id", new_callable=AsyncMock
    )
    mock_get_item_svc.return_value = sample_item_with_photo

    invalid_payload = {"stage": 123}  # Stage should be string

    headers = {**common_headers, **auth_headers}
    response = client.put(
        f"/api/items/{TEST_ITEM_ID_1}/photos/{EXISTING_PHOTO_ID}",
        json=invalid_payload,
        headers=headers,
    )

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    # FastAPI validation happens before the endpoint function is called, so
    # get_item_by_id is never awaited


@pytest.mark.asyncio
async def test_update_photo_details_firestore_error(
    client: TestClient, mocker, auth_headers, common_headers
):
    """Test PUT /photos/{photo_id} when firestore service fails."""
    mock_get_item_svc = mocker.patch(
        "services.firestore_service.get_item_by_id", new_callable=AsyncMock
    )
    mock_get_item_svc.return_value = sample_item_with_photo

    mock_update_details = mocker.patch(
        "services.firestore_service.update_photo_details_in_item",
        new_callable=AsyncMock,
    )
    mock_update_details.side_effect = Exception("Firestore update failed")

    headers = {**common_headers, **auth_headers}
    response = client.put(
        f"/api/items/{TEST_ITEM_ID_1}/photos/{EXISTING_PHOTO_ID}",
        json=photo_update_payload,
        headers=headers,
    )

    assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    # Check specific detail from the handler in update_photo_details endpoint
    assert response.json()["detail"] == "Failed to update photo details."
    mock_get_item_svc.assert_awaited_once_with(
        TEST_ITEM_ID_1, user_id="test-firebase-uid-123"
    )
    mock_update_details.assert_awaited_once_with(
        TEST_ITEM_ID_1, EXISTING_PHOTO_ID, ANY, user_id="test-firebase-uid-123"
    )
