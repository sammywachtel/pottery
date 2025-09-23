# tests/integration/test_integration_items_photos.py
import pytest # Import pytest for markers
from fastapi.testclient import TestClient
from fastapi import status
from datetime import datetime, timezone, timedelta
import uuid
import io
import time # For potential delays if needed
from pathlib import Path # Import Path for file handling
# Imports for direct GCS checks
from google.cloud import storage
from google.cloud.exceptions import NotFound as GoogleNotFound
from config import settings # Assumes config points to TEST environment

# Use the resource_manager fixture from integration conftest
pytest_plugins = ["tests.integration.conftest"]

# WARNING: These tests interact with REAL GCP services.
# Ensure your environment is configured to point to TEST resources
# and that appropriate authentication is set up.

# --- Test Data ---
NOW_UTC = datetime.now(timezone.utc)
# Function to generate unique names/data for each test run if needed
def generate_unique_name(base="TestItem"):
    return f"{base}-{uuid.uuid4()}"

def create_item_payload(name=None):
    return {
        "name": name or generate_unique_name(),
        "clayType": "IntegrationTestClay",
        "location": "TestLocation",
        # Send datetime as ISO string with Z for UTC
        "createdDateTime": datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')
    }

def update_item_payload(original_payload):
    updated = original_payload.copy()
    updated["name"] = generate_unique_name("UpdatedItem")
    updated["glaze"] = "IntegrationGlaze"
    updated["note"] = "Updated via integration test"
    # Update datetime if needed, or keep original
    updated["createdDateTime"] = datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')
    return updated

# --- Tests ---

# *** ADDED MARKER ***
@pytest.mark.integration
@pytest.mark.asyncio
async def test_item_create_get_delete_cycle(client: TestClient, resource_manager, auth_headers):
    """Tests creating, retrieving, and deleting an item."""
    created_item_ids, _ = resource_manager # Get the set to store created IDs
    headers = {**auth_headers, "Content-Type": "application/json"}
    payload = create_item_payload()
    item_id = None

    # 1. Create Item
    response_create = client.post("/api/items", json=payload, headers=headers)
    assert response_create.status_code == status.HTTP_201_CREATED
    created_data = response_create.json()
    item_id = created_data.get("id")
    assert item_id is not None
    created_item_ids.add(item_id) # Register for cleanup
    assert created_data["name"] == payload["name"]
    assert created_data["clayType"] == payload["clayType"]
    assert created_data["photos"] == [] # Should be empty initially
    assert created_data["createdTimezone"] == "UTC" # Check derived timezone

    # 2. Get Created Item
    response_get = client.get(f"/api/items/{item_id}", headers=auth_headers)
    assert response_get.status_code == status.HTTP_200_OK
    get_data = response_get.json()
    assert get_data["id"] == item_id
    assert get_data["name"] == payload["name"]
    # Compare datetime strings (or parse back to datetime objects)
    assert get_data["createdDateTime"] == created_data["createdDateTime"]

    # 3. List Items (verify created item is present)
    response_list = client.get("/api/items", headers=auth_headers)
    assert response_list.status_code == status.HTTP_200_OK
    list_data = response_list.json()
    assert isinstance(list_data, list)
    found_in_list = any(item['id'] == item_id for item in list_data)
    assert found_in_list, f"Created item {item_id} not found in list"

    # 4. Delete Item (cleanup is handled by fixture, but test the endpoint)
    response_delete = client.delete(f"/api/items/{item_id}", headers=auth_headers)
    assert response_delete.status_code == status.HTTP_204_NO_CONTENT

    # 5. Verify Deletion by trying to Get again
    response_get_after_delete = client.get(f"/api/items/{item_id}", headers=auth_headers)
    assert response_get_after_delete.status_code == status.HTTP_404_NOT_FOUND

    # Remove from cleanup list as we explicitly deleted it
    if item_id in created_item_ids:
        created_item_ids.remove(item_id)

# *** ADDED MARKER ***
@pytest.mark.integration
@pytest.mark.asyncio
async def test_item_update_cycle(client: TestClient, resource_manager, auth_headers):
    """Tests creating, updating, and verifying update of an item."""
    created_item_ids, _ = resource_manager
    headers = {**auth_headers, "Content-Type": "application/json"}
    create_payload_data = create_item_payload()
    item_id = None

    # 1. Create Item
    response_create = client.post("/api/items", json=create_payload_data, headers=headers)
    assert response_create.status_code == status.HTTP_201_CREATED
    item_id = response_create.json()["id"]
    created_item_ids.add(item_id)

    # 2. Prepare and Send Update
    update_payload_data = update_item_payload(create_payload_data)
    response_update = client.put(f"/api/items/{item_id}", json=update_payload_data, headers=headers)
    assert response_update.status_code == status.HTTP_200_OK
    update_response_data = response_update.json()
    assert update_response_data["id"] == item_id
    assert update_response_data["name"] == update_payload_data["name"]
    assert update_response_data["glaze"] == update_payload_data["glaze"]
    assert update_response_data["note"] == update_payload_data["note"]
    assert update_response_data["createdDateTime"] == update_payload_data["createdDateTime"]

    # 3. Get Item and Verify Update Persisted
    response_get = client.get(f"/api/items/{item_id}", headers=auth_headers)
    assert response_get.status_code == status.HTTP_200_OK
    get_data = response_get.json()
    assert get_data["id"] == item_id
    assert get_data["name"] == update_payload_data["name"]
    assert get_data["glaze"] == update_payload_data["glaze"]
    assert get_data["note"] == update_payload_data["note"]
    assert get_data["createdDateTime"] == update_payload_data["createdDateTime"]

# *** ADDED MARKER ***
@pytest.mark.integration
@pytest.mark.asyncio
async def test_get_nonexistent_item(client: TestClient, auth_headers):
    """Test getting an item that does not exist."""
    non_existent_id = str(uuid.uuid4())
    response_get = client.get(f"/api/items/{non_existent_id}", headers=auth_headers)
    assert response_get.status_code == status.HTTP_404_NOT_FOUND

# *** ADDED MARKER ***
@pytest.mark.integration
@pytest.mark.asyncio
async def test_photo_upload_get_delete_cycle(client: TestClient, resource_manager, auth_headers):
    """Tests uploading a real photo file, verifying, and deleting it."""
    created_item_ids, created_gcs_paths = resource_manager
    headers = {**auth_headers, "Content-Type": "application/json"}
    item_payload = create_item_payload()
    item_id = None
    photo_id = None
    gcs_path = None

    # *** Define path to the test image ***
    try:
        # Assumes tests run from project root
        current_dir = Path(__file__).parent
        # Go up one level from integration tests dir to main tests dir
        image_path = current_dir.parent / "images" / "crackle.jpeg"
        assert image_path.is_file(), f"Test image not found at {image_path}"
    except Exception as e:
         pytest.fail(f"Could not determine or find image path: {e}")

    file_name = image_path.name
    content_type = "image/jpeg" # Set appropriate content type

    # 1. Create Item to associate photo with
    response_create = client.post("/api/items", json=item_payload, headers=headers)
    assert response_create.status_code == status.HTTP_201_CREATED
    item_id = response_create.json()["id"]
    created_item_ids.add(item_id)

    # 2. Upload Photo using the actual file
    form_data = { "photo_stage": "IntegrationTestStage" }
    # *** Open the file in binary read mode for upload ***
    with open(image_path, "rb") as f:
        files = {'file': (file_name, f, content_type)}
        response_upload = client.post(
            f"/api/items/{item_id}/photos", data=form_data, files=files, headers=auth_headers
        )

    assert response_upload.status_code == status.HTTP_201_CREATED
    upload_data = response_upload.json()
    photo_id = upload_data.get("id")
    assert photo_id is not None
    assert upload_data["stage"] == form_data["photo_stage"]
    assert upload_data["fileName"] == file_name
    assert "signedUrl" in upload_data
    assert upload_data["signedUrl"] is not None

    # Derive expected GCS path (needs to match logic in gcs_service._get_gcs_path)
    # Assuming extension is preserved and lowercase: '.jpeg'
    gcs_path = f"items/{item_id}/{photo_id}.jpeg" # Adjust extension if needed
    created_gcs_paths.add(gcs_path) # Register for cleanup

    # Allow time for potential GCS/Firestore eventual consistency
    time.sleep(2)

    # 3. Get Item and Verify Photo Metadata
    response_get = client.get(f"/api/items/{item_id}", headers=auth_headers)
    assert response_get.status_code == status.HTTP_200_OK
    get_data = response_get.json()
    assert len(get_data["photos"]) == 1
    photo_metadata = get_data["photos"][0]
    assert photo_metadata["id"] == photo_id
    assert photo_metadata["stage"] == form_data["photo_stage"]
    assert photo_metadata["fileName"] == file_name
    assert photo_metadata["uploadedTimezone"] == "UTC"
    # Verify that the signed URL is present
    assert "signedUrl" in photo_metadata
    assert photo_metadata["signedUrl"] is not None
    assert photo_metadata["signedUrl"].startswith("https://")

    # Verify file exists in GCS directly
    try:
        gcs_client = storage.Client(project=settings.gcp_project_id)
        bucket = gcs_client.bucket(settings.gcs_bucket_name)
        blob = bucket.blob(gcs_path)
        assert blob.exists(), f"Blob {gcs_path} not found in GCS after upload"
    except Exception as e:
        pytest.fail(f"Direct GCS check after upload failed: {e}")

    # 4. Delete Photo
    response_delete_photo = client.delete(f"/api/items/{item_id}/photos/{photo_id}", headers=auth_headers)
    assert response_delete_photo.status_code == status.HTTP_204_NO_CONTENT
    if gcs_path in created_gcs_paths:
         created_gcs_paths.remove(gcs_path) # Remove from cleanup list as we explicitly delete

    # Allow time for deletion consistency
    time.sleep(2)

    # 5. Verify Photo Deletion (check item metadata)
    response_get_after_delete = client.get(f"/api/items/{item_id}", headers=auth_headers)
    assert response_get_after_delete.status_code == status.HTTP_200_OK
    get_data_after_delete = response_get_after_delete.json()
    assert len(get_data_after_delete["photos"]) == 0

    # Verify file is gone from GCS directly
    try:
        gcs_client = storage.Client(project=settings.gcp_project_id)
        bucket = gcs_client.bucket(settings.gcs_bucket_name)
        blob = bucket.blob(gcs_path)
        assert not blob.exists(), f"Blob {gcs_path} still exists after delete"
    except GoogleNotFound:
        pass # Expected outcome
    except Exception as e:
        pytest.fail(f"Direct GCS check after delete failed: {e}")

# *** ADDED MARKER ***
@pytest.mark.integration
@pytest.mark.asyncio
async def test_photo_update_details(client: TestClient, resource_manager, auth_headers):
    """Tests updating photo metadata (does not involve file upload)."""
    created_item_ids, created_gcs_paths = resource_manager
    headers = {**auth_headers, "Content-Type": "application/json"}
    item_payload = create_item_payload()
    item_id = None
    photo_id = None
    gcs_path = None

    # 1. Create Item
    response_create = client.post("/api/items", json=item_payload, headers=headers)
    assert response_create.status_code == status.HTTP_201_CREATED
    item_id = response_create.json()["id"]
    created_item_ids.add(item_id)

    # 2. Upload Photo (using the real file logic from previous test)
    try:
        current_dir = Path(__file__).parent
        image_path = current_dir.parent / "images" / "crackle.jpeg"
        assert image_path.is_file(), f"Test image not found at {image_path}"
    except Exception as e:
         pytest.fail(f"Could not determine or find image path: {e}")

    file_name = image_path.name
    content_type = "image/jpeg"
    form_data = { "photo_stage": "BeforeUpdate" } # Initial stage
    with open(image_path, "rb") as f:
        files = {'file': (file_name, f, content_type)}
        response_upload = client.post(f"/api/items/{item_id}/photos", data=form_data, files=files, headers=auth_headers)

    assert response_upload.status_code == status.HTTP_201_CREATED
    photo_id = response_upload.json()["id"]
    gcs_path = f"items/{item_id}/{photo_id}.jpeg" # Assuming extension logic
    created_gcs_paths.add(gcs_path)

    # 3. Update Photo Details
    photo_update_payload = {
        "stage": "AfterUpdate",
        "imageNote": "Details updated via integration test"
    }
    response_update = client.put(
        f"/api/items/{item_id}/photos/{photo_id}",
        json=photo_update_payload,
        headers=headers
    )
    assert response_update.status_code == status.HTTP_200_OK
    update_response_data = response_update.json()
    assert update_response_data["id"] == photo_id
    assert update_response_data["stage"] == photo_update_payload["stage"]
    assert update_response_data["imageNote"] == photo_update_payload["imageNote"]

    # 4. Get Item and Verify Updated Photo Metadata
    response_get = client.get(f"/api/items/{item_id}", headers=auth_headers)
    assert response_get.status_code == status.HTTP_200_OK
    get_data = response_get.json()
    assert len(get_data["photos"]) == 1
    photo_metadata = get_data["photos"][0]
    assert photo_metadata["id"] == photo_id
    assert photo_metadata["stage"] == photo_update_payload["stage"]
    assert photo_metadata["imageNote"] == photo_update_payload["imageNote"]
    # Verify that the signed URL is present
    assert "signedUrl" in photo_metadata
    assert photo_metadata["signedUrl"] is not None
    assert photo_metadata["signedUrl"].startswith("https://")
