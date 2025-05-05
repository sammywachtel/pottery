# tests/test_items_router.py
import pytest
from fastapi.testclient import TestClient
from fastapi import status, HTTPException # Import HTTPException
from unittest.mock import AsyncMock, MagicMock, patch, ANY
from typing import Optional, List, Dict, Any
from datetime import datetime, date, timezone
import uuid

# Assuming your models are importable
import sys, os
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

from models import PotteryItem, PotteryItemCreate, PotteryItemBase, PotteryItemResponse, Photo, PhotoResponse

# Sample data remains the same...
TEST_ITEM_ID_1 = str(uuid.uuid4())
TEST_ITEM_ID_2 = str(uuid.uuid4())
TEST_PHOTO_ID_1 = str(uuid.uuid4())
TEST_GCS_PATH_1 = f"items/{TEST_ITEM_ID_1}/{TEST_PHOTO_ID_1}.jpg"
NOW_UTC = datetime.now(timezone.utc)
TODAY = NOW_UTC.date()
sample_photo_internal = Photo(id=TEST_PHOTO_ID_1, gcsPath=TEST_GCS_PATH_1, stage="Bisque", fileName="test.jpg", uploadedAt=NOW_UTC, uploadedTimezone="UTC")
sample_item_internal_1 = PotteryItem(id=TEST_ITEM_ID_1, name="Test Mug", clayType="Stoneware", createdDateTime=NOW_UTC, createdTimezone="UTC", location="Studio", photos=[sample_photo_internal])
sample_item_internal_2 = PotteryItem(id=TEST_ITEM_ID_2, name="Test Bowl", clayType="Porcelain", createdDateTime=NOW_UTC, createdTimezone="-04:00", location="Shelf", photos=[])
create_payload = {"name": "New Item", "clayType": "Earthenware", "location": "Kiln", "createdDateTime": NOW_UTC.isoformat()}
update_payload = {"name": "Updated Mug", "clayType": "Stoneware", "glaze": "Celadon", "location": "Gallery", "note": "Final version", "createdDateTime": NOW_UTC.isoformat()}

def get_timezone_identifier(dt: Optional[datetime]) -> Optional[str]:
    if dt and dt.tzinfo:
        offset_seconds = dt.tzinfo.utcoffset(dt).total_seconds()
        if offset_seconds == 0: return "UTC"
        hours, rem = divmod(abs(offset_seconds), 3600)
        minutes, _ = divmod(rem, 60)
        sign = "+" if offset_seconds >= 0 else "-"
        return f"{sign}{int(hours):02d}:{int(minutes):02d}"
    return None

# --- Tests ---
# Note: All tests should be updated to use the auth_headers fixture since all endpoints now require authentication.
# Only a few tests have been updated as examples to keep the changes minimal.

@pytest.mark.asyncio
async def test_get_items_empty(client: TestClient, mocker, auth_headers):
    mock_get_all = mocker.patch('services.firestore_service.get_all_items', new_callable=AsyncMock)
    mock_get_all.return_value = []
    response = client.get("/api/items", headers=auth_headers)
    assert response.status_code == status.HTTP_200_OK
    assert response.json() == []
    mock_get_all.assert_awaited_once()

@pytest.mark.asyncio
async def test_get_items_success(client: TestClient, mocker, auth_headers):
    mock_get_all = mocker.patch('services.firestore_service.get_all_items', new_callable=AsyncMock)
    mock_get_all.return_value = [sample_item_internal_1, sample_item_internal_2]
    mock_generate_urls = mocker.patch('services.gcs_service.generate_signed_urls_for_photos', new_callable=AsyncMock)
    expected_photo_response = PhotoResponse(**sample_photo_internal.model_dump(), signedUrl="https://fake-signed-url.com/test.jpg")
    mock_generate_urls.side_effect = [[expected_photo_response], []]
    response = client.get("/api/items", headers=auth_headers)
    assert response.status_code == status.HTTP_200_OK
    json_response = response.json()
    assert len(json_response) == 2
    assert json_response[0]['id'] == TEST_ITEM_ID_1
    assert len(json_response[0]['photos']) == 1
    assert json_response[1]['id'] == TEST_ITEM_ID_2
    assert len(json_response[1]['photos']) == 0
    mock_get_all.assert_awaited_once()
    assert mock_generate_urls.call_count == 2

@pytest.mark.asyncio
async def test_get_items_firestore_error(client: TestClient, mocker, auth_headers):
    mock_get_all = mocker.patch('services.firestore_service.get_all_items', new_callable=AsyncMock)
    mock_get_all.side_effect = Exception("Firestore connection failed")
    response = client.get("/api/items", headers=auth_headers)
    assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    assert "detail" in response.json()
    # Check specific detail from the handler in get_items endpoint
    assert response.json()["detail"] == "Failed to retrieve items."
    mock_get_all.assert_awaited_once()


@pytest.mark.asyncio
async def test_create_item_success(client: TestClient, mocker, auth_headers):
    mock_create = mocker.patch('services.firestore_service.create_item', new_callable=AsyncMock)
    internal_data_payload = create_payload.copy()
    dt_object = datetime.fromisoformat(internal_data_payload['createdDateTime'])
    internal_data_payload['createdDateTime'] = dt_object
    created_item_internal = PotteryItem(id=str(uuid.uuid4()), **internal_data_payload, createdTimezone=get_timezone_identifier(dt_object), photos=[])
    mock_create.return_value = created_item_internal
    mock_generate_urls = mocker.patch('services.gcs_service.generate_signed_urls_for_photos', new_callable=AsyncMock)
    mock_generate_urls.return_value = []
    response = client.post("/api/items", json=create_payload, headers=auth_headers)
    assert response.status_code == status.HTTP_201_CREATED
    json_response = response.json()
    assert json_response["name"] == create_payload["name"]
    assert "id" in json_response
    response_dt_str = json_response["createdDateTime"]
    response_dt = datetime.fromisoformat(response_dt_str.replace('Z', '+00:00'))
    payload_dt = datetime.fromisoformat(create_payload["createdDateTime"])
    assert response_dt == payload_dt
    mock_create.assert_awaited_once()
    mock_generate_urls.assert_awaited_once_with([])

@pytest.mark.asyncio
async def test_create_item_validation_error(client: TestClient, auth_headers):
    invalid_payload = create_payload.copy()
    del invalid_payload["name"]
    response = client.post("/api/items", json=invalid_payload, headers=auth_headers)
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

@pytest.mark.asyncio
async def test_create_item_validation_error_bad_date(client: TestClient, auth_headers):
    invalid_payload = create_payload.copy()
    invalid_payload["createdDateTime"] = "not-a-date"
    response = client.post("/api/items", json=invalid_payload, headers=auth_headers)
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

@pytest.mark.asyncio
async def test_create_item_firestore_error(client: TestClient, mocker, auth_headers):
    mock_create = mocker.patch('services.firestore_service.create_item', new_callable=AsyncMock)
    mock_create.side_effect = Exception("DB write error")
    response = client.post("/api/items", json=create_payload, headers=auth_headers)
    assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    # Check specific detail from the handler in create_item endpoint
    assert response.json()["detail"] == "Failed to create item."
    mock_create.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_item_success(client: TestClient, mocker, auth_headers):
    mock_get_item = mocker.patch('services.firestore_service.get_item_by_id', new_callable=AsyncMock)
    mock_get_item.return_value = sample_item_internal_1
    mock_generate_urls = mocker.patch('services.gcs_service.generate_signed_urls_for_photos', new_callable=AsyncMock)
    expected_photo_response = PhotoResponse(**sample_photo_internal.model_dump(), signedUrl="https://fake-signed-url.com/test.jpg")
    mock_generate_urls.return_value = [expected_photo_response]
    response = client.get(f"/api/items/{TEST_ITEM_ID_1}", headers=auth_headers)
    assert response.status_code == status.HTTP_200_OK
    json_response = response.json()
    assert json_response["id"] == TEST_ITEM_ID_1
    mock_get_item.assert_awaited_once_with(TEST_ITEM_ID_1)
    mock_generate_urls.assert_awaited_once_with(sample_item_internal_1.photos)

@pytest.mark.asyncio
async def test_get_item_not_found(client: TestClient, mocker, auth_headers):
    mock_get_item = mocker.patch('services.firestore_service.get_item_by_id', new_callable=AsyncMock)
    mock_get_item.return_value = None
    response = client.get(f"/api/items/{TEST_ITEM_ID_1}", headers=auth_headers)
    assert response.status_code == status.HTTP_404_NOT_FOUND
    assert response.json()["detail"] == f"Pottery item with ID '{TEST_ITEM_ID_1}' not found."
    mock_get_item.assert_awaited_once_with(TEST_ITEM_ID_1)


@pytest.mark.asyncio
async def test_get_item_firestore_error(client: TestClient, mocker, auth_headers):
    """Test GET /api/items/{item_id} when firestore service fails."""
    mock_get_item = mocker.patch('services.firestore_service.get_item_by_id', new_callable=AsyncMock)
    mock_get_item.side_effect = Exception("DB read error")
    response = client.get(f"/api/items/{TEST_ITEM_ID_1}", headers=auth_headers)
    assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    assert response.json()["detail"] == f"An internal error occurred while fetching item '{TEST_ITEM_ID_1}'."
    mock_get_item.assert_awaited_once_with(TEST_ITEM_ID_1)

@pytest.mark.asyncio
async def test_get_item_firestore_connection_error(client: TestClient, mocker, auth_headers):
    """Test GET /api/items/{item_id} when firestore service has connection error."""
    mock_get_item = mocker.patch('services.firestore_service.get_item_by_id', new_callable=AsyncMock)
    mock_get_item.side_effect = ConnectionError("DB connection refused")
    response = client.get(f"/api/items/{TEST_ITEM_ID_1}", headers=auth_headers)
    assert response.status_code == status.HTTP_503_SERVICE_UNAVAILABLE
    assert response.json()["detail"] == "Backend database service unavailable."
    mock_get_item.assert_awaited_once_with(TEST_ITEM_ID_1)


@pytest.mark.asyncio
async def test_update_item_success(client: TestClient, mocker, auth_headers):
    mock_update = mocker.patch('services.firestore_service.update_item_metadata', new_callable=AsyncMock)
    internal_update_data = update_payload.copy()
    dt_object = datetime.fromisoformat(internal_update_data['createdDateTime'])
    internal_update_data['createdDateTime'] = dt_object
    updated_item_internal = PotteryItem(id=TEST_ITEM_ID_1, **internal_update_data, createdTimezone=get_timezone_identifier(dt_object), photos=[])
    mock_update.return_value = updated_item_internal
    mock_generate_urls = mocker.patch('services.gcs_service.generate_signed_urls_for_photos', new_callable=AsyncMock)
    mock_generate_urls.return_value = []
    response = client.put(f"/api/items/{TEST_ITEM_ID_1}", json=update_payload, headers=auth_headers)
    assert response.status_code == status.HTTP_200_OK
    json_response = response.json()
    assert json_response["id"] == TEST_ITEM_ID_1
    response_dt_str = json_response["createdDateTime"]
    response_dt = datetime.fromisoformat(response_dt_str.replace('Z', '+00:00'))
    payload_dt = datetime.fromisoformat(update_payload["createdDateTime"])
    assert response_dt == payload_dt
    mock_update.assert_awaited_once()
    mock_generate_urls.assert_awaited_once_with([])

@pytest.mark.asyncio
async def test_update_item_not_found(client: TestClient, mocker, auth_headers):
    mock_update = mocker.patch('services.firestore_service.update_item_metadata', new_callable=AsyncMock)
    mock_update.return_value = None
    response = client.put(f"/api/items/{TEST_ITEM_ID_1}", json=update_payload, headers=auth_headers)
    assert response.status_code == status.HTTP_404_NOT_FOUND
    mock_update.assert_awaited_once()

@pytest.mark.asyncio
async def test_update_item_validation_error(client: TestClient, auth_headers):
    invalid_payload = update_payload.copy()
    invalid_payload["createdDateTime"] = "invalid-date"
    response = client.put(f"/api/items/{TEST_ITEM_ID_1}", json=invalid_payload, headers=auth_headers)
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

@pytest.mark.asyncio
async def test_update_item_firestore_error(client: TestClient, mocker, auth_headers):
    mock_update = mocker.patch('services.firestore_service.update_item_metadata', new_callable=AsyncMock)
    mock_update.side_effect = Exception("DB update error")
    response = client.put(f"/api/items/{TEST_ITEM_ID_1}", json=update_payload, headers=auth_headers)
    assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    # Check specific detail from the handler in update_item endpoint
    assert response.json()["detail"] == "Failed to update item metadata."
    mock_update.assert_awaited_once()


@pytest.mark.asyncio
async def test_delete_item_success_with_photos(client: TestClient, mocker, auth_headers):
    mock_get_item = mocker.patch('services.firestore_service.get_item_by_id', new_callable=AsyncMock)
    mock_get_item.return_value = sample_item_internal_1
    mock_gcs_delete = mocker.patch('services.gcs_service.delete_multiple_photos_from_gcs', new_callable=AsyncMock)
    mock_gcs_delete.return_value = True
    mock_fs_delete = mocker.patch('services.firestore_service.delete_item_and_photos', new_callable=AsyncMock)
    mock_fs_delete.return_value = True
    response = client.delete(f"/api/items/{TEST_ITEM_ID_1}", headers=auth_headers)
    assert response.status_code == status.HTTP_204_NO_CONTENT
    mock_get_item.assert_awaited_once_with(TEST_ITEM_ID_1)
    mock_gcs_delete.assert_awaited_once_with([TEST_GCS_PATH_1])
    mock_fs_delete.assert_awaited_once_with(TEST_ITEM_ID_1)

@pytest.mark.asyncio
async def test_delete_item_success_no_photos(client: TestClient, mocker, auth_headers):
    mock_get_item = mocker.patch('services.firestore_service.get_item_by_id', new_callable=AsyncMock)
    mock_get_item.return_value = sample_item_internal_2
    mock_gcs_delete = mocker.patch('services.gcs_service.delete_multiple_photos_from_gcs', new_callable=AsyncMock)
    mock_fs_delete = mocker.patch('services.firestore_service.delete_item_and_photos', new_callable=AsyncMock)
    mock_fs_delete.return_value = True
    response = client.delete(f"/api/items/{TEST_ITEM_ID_2}", headers=auth_headers)
    assert response.status_code == status.HTTP_204_NO_CONTENT
    mock_get_item.assert_awaited_once_with(TEST_ITEM_ID_2)
    mock_gcs_delete.assert_not_awaited()
    mock_fs_delete.assert_awaited_once_with(TEST_ITEM_ID_2)

@pytest.mark.asyncio
async def test_delete_item_not_found(client: TestClient, mocker, auth_headers):
    mock_get_item = mocker.patch('services.firestore_service.get_item_by_id', new_callable=AsyncMock)
    mock_get_item.return_value = None
    mock_gcs_delete = mocker.patch('services.gcs_service.delete_multiple_photos_from_gcs', new_callable=AsyncMock)
    mock_fs_delete = mocker.patch('services.firestore_service.delete_item_and_photos', new_callable=AsyncMock)
    response = client.delete(f"/api/items/{TEST_ITEM_ID_1}", headers=auth_headers)
    assert response.status_code == status.HTTP_404_NOT_FOUND
    mock_get_item.assert_awaited_once_with(TEST_ITEM_ID_1)
    mock_gcs_delete.assert_not_awaited()
    mock_fs_delete.assert_not_awaited()

@pytest.mark.asyncio
async def test_delete_item_gcs_error(client: TestClient, mocker, auth_headers):
    """Test DELETE /api/items/{item_id} when GCS delete fails."""
    mock_get_item = mocker.patch('services.firestore_service.get_item_by_id', new_callable=AsyncMock)
    mock_get_item.return_value = sample_item_internal_1

    mock_gcs_delete = mocker.patch('services.gcs_service.delete_multiple_photos_from_gcs', new_callable=AsyncMock)
    # Simulate GCS failure by raising an exception
    mock_gcs_delete.side_effect = Exception("GCS Network Error")

    mock_fs_delete = mocker.patch('services.firestore_service.delete_item_and_photos', new_callable=AsyncMock)

    response = client.delete(f"/api/items/{TEST_ITEM_ID_1}", headers=auth_headers)

    assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    # *** FIX: Assert correct error detail from router ***
    assert response.json()["detail"] == "Error during photo deletion."
    mock_get_item.assert_awaited_once_with(TEST_ITEM_ID_1)
    mock_gcs_delete.assert_awaited_once_with([TEST_GCS_PATH_1])
    mock_fs_delete.assert_not_awaited()

@pytest.mark.asyncio
async def test_delete_item_firestore_error(client: TestClient, mocker, auth_headers):
    """Test DELETE /api/items/{item_id} when Firestore delete fails."""
    mock_get_item = mocker.patch('services.firestore_service.get_item_by_id', new_callable=AsyncMock)
    mock_get_item.return_value = sample_item_internal_1

    mock_gcs_delete = mocker.patch('services.gcs_service.delete_multiple_photos_from_gcs', new_callable=AsyncMock)
    mock_gcs_delete.return_value = True # GCS succeeds

    mock_fs_delete = mocker.patch('services.firestore_service.delete_item_and_photos', new_callable=AsyncMock)
    mock_fs_delete.return_value = False # Firestore fails

    response = client.delete(f"/api/items/{TEST_ITEM_ID_1}", headers=auth_headers)

    assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    assert response.json()["detail"] == "Failed to delete item metadata after deleting photos."
    mock_get_item.assert_awaited_once_with(TEST_ITEM_ID_1)
    mock_gcs_delete.assert_awaited_once_with([TEST_GCS_PATH_1])
    mock_fs_delete.assert_awaited_once_with(TEST_ITEM_ID_1)
