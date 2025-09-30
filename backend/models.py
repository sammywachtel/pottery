import uuid as uuid_pkg  # Alias to avoid conflict with field name
from datetime import datetime, timezone  # Added timezone
from typing import List, Optional, Union

from pydantic import BaseModel, Field

# --- Measurement Schemas ---


class MeasurementDetail(BaseModel):
    """Individual measurement set (height, width, depth)."""

    height: Optional[float] = None
    width: Optional[float] = None
    depth: Optional[float] = None


class Measurements(BaseModel):
    """Measurements at different stages."""

    greenware: Optional[MeasurementDetail] = None
    bisque: Optional[MeasurementDetail] = None
    final: Optional[MeasurementDetail] = None


# --- Photo Schemas ---


class PhotoBase(BaseModel):
    """Base properties for a photo."""

    stage: str = Field(..., description="Stage of the pottery when photo was taken")
    imageNote: Optional[str] = Field(None, description="Optional note about the photo")
    fileName: Optional[str] = Field(
        None, description="Original filename, useful for display"
    )


class Photo(PhotoBase):
    """
    Internal Photo model (as stored in Firestore).
    Includes GCS path and internal ID. uploadedAt is stored as UTC.
    """

    id: str = Field(
        default_factory=lambda: str(uuid_pkg.uuid4()),
        description="Unique ID for the photo",
    )
    gcsPath: str = Field(
        ...,
        description="Path to the photo object in GCS "
        "(e.g., items/item_id/photo_id.jpg)",
    )
    uploadedAt: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="Timestamp (UTC) when the photo was uploaded",
    )


class PhotoResponse(PhotoBase):
    """
    Photo model for API responses.
    Includes signed URL instead of GCS path. Returns UTC time and timezone.
    """

    id: str = Field(..., description="Unique ID for the photo")
    signedUrl: Optional[str] = Field(
        None,
        description="Temporary signed URL to access the photo file in GCS. "
        "May be null if generation failed.",
    )
    uploadedAt: datetime = Field(
        ..., description="Timestamp (UTC) when the photo was uploaded"
    )


class PhotoUpdate(BaseModel):
    """Schema for updating photo metadata fields (stage, imageNote)."""

    stage: Optional[str] = Field(None, description="New stage for the photo")
    imageNote: Optional[str] = Field(None, description="New note for the photo")


# --- Pottery Item Schemas ---


class PotteryItemBase(BaseModel):
    """Base properties for a pottery item."""

    name: str
    clayType: str
    currentStatus: str = Field(
        default="greenware",
        description="Current firing status: greenware, bisque, or final",
    )
    glaze: Optional[str] = None
    location: str
    note: Optional[str] = None
    createdDateTime: datetime = Field(
        ...,
        description="Timestamp item was created/started (UTC)",
    )
    measurements: Optional[Measurements] = None


class PotteryItemCreate(PotteryItemBase):
    """Schema for creating a new pottery item."""

    pass


class PotteryItem(PotteryItemBase):
    """Internal PotteryItem model (as stored in Firestore).
    Includes Firestore document ID and internal Photo models.
    createdDateTime is stored as UTC.
    """

    id: str = Field(..., description="Firestore document ID")
    user_id: str = Field(..., description="Username of the user who owns this item")
    photos: List[Photo] = Field(
        [], description="List of photo metadata stored for this item"
    )


class PotteryItemResponse(PotteryItemBase):
    """PotteryItem model for API responses.
    Includes Firestore document ID and PhotoResponse models (with signed URLs).
    Returns UTC time and original timezone identifier.
    """

    id: str = Field(..., description="Firestore document ID")
    user_id: str = Field(..., description="Username of the user who owns this item")
    photos: List[PhotoResponse] = Field(
        [], description="List of photo metadata with signed URLs"
    )


# --- Error Schemas (Matching OpenAPI spec) ---


class ValidationError(BaseModel):
    """Standard FastAPI validation error detail."""

    loc: List[Union[str, int]] = Field(..., title="Location")
    msg: str = Field(..., title="Message")
    type: str = Field(..., title="Error Type")


class HTTPValidationError(BaseModel):
    """Standard FastAPI validation error response."""

    detail: Optional[List[ValidationError]] = None


class HTTPError(BaseModel):
    """Simple error model for non-validation errors."""

    detail: str = Field(..., description="A human-readable error message.")
