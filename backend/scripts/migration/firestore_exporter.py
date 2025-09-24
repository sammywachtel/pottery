#!/usr/bin/env python3
"""
Firestore Data Exporter

Exports all pottery items and photos from Firestore to JSON format
for migration to Supabase PostgreSQL database.
"""

import asyncio
import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, List

from google.cloud import firestore

from config import settings


class FirestoreExporter:
    """Exports data from Firestore for migration."""

    def __init__(self):
        """Initialize Firestore client."""
        self.db = firestore.Client(
            project=settings.gcp_project_id,
            database=settings.firestore_database_id
        )
        self.collection_name = settings.firestore_collection
        self.logger = logging.getLogger(__name__)

    def export_all_data(self, output_dir: str = "migration_data") -> Dict:
        """
        Export all pottery items and photos to JSON files.

        Args:
            output_dir: Directory to save exported data

        Returns:
            Dict with export statistics
        """
        output_path = Path(output_dir)
        output_path.mkdir(exist_ok=True)

        # Export pottery items
        items_data = self._export_pottery_items()
        items_file = output_path / "pottery_items.json"

        with open(items_file, 'w', encoding='utf-8') as f:
            json.dump(items_data, f, indent=2, default=str)

        # Extract and export photos
        photos_data = self._extract_photos_from_items(items_data)
        photos_file = output_path / "photos.json"

        with open(photos_file, 'w', encoding='utf-8') as f:
            json.dump(photos_data, f, indent=2, default=str)

        # Export metadata
        metadata = {
            "export_timestamp": datetime.utcnow().isoformat(),
            "source_database": "firestore",
            "gcp_project": settings.gcp_project_id,
            "collection": self.collection_name,
            "total_items": len(items_data),
            "total_photos": len(photos_data),
            "files_created": [
                str(items_file),
                str(photos_file)
            ]
        }

        metadata_file = output_path / "export_metadata.json"
        with open(metadata_file, 'w', encoding='utf-8') as f:
            json.dump(metadata, f, indent=2)

        self.logger.info(f"Export completed: {metadata['total_items']} items, "
                        f"{metadata['total_photos']} photos")

        return metadata

    def _export_pottery_items(self) -> List[Dict]:
        """Export all pottery items from Firestore."""
        self.logger.info(f"Exporting items from collection: {self.collection_name}")

        items = []
        docs = self.db.collection(self.collection_name).stream()

        for doc in docs:
            item_data = doc.to_dict()
            item_data['id'] = doc.id  # Include Firestore document ID

            # Convert Firestore timestamps to ISO format
            if 'createdDateTime' in item_data:
                item_data['createdDateTime'] = item_data['createdDateTime'].isoformat()

            # Process photos if they exist
            if 'photos' in item_data:
                for photo in item_data['photos']:
                    if 'uploadedAt' in photo:
                        photo['uploadedAt'] = photo['uploadedAt'].isoformat()

            items.append(item_data)

        self.logger.info(f"Exported {len(items)} pottery items")
        return items

    def _extract_photos_from_items(self, items_data: List[Dict]) -> List[Dict]:
        """Extract photos from items into separate list."""
        photos = []

        for item in items_data:
            item_id = item['id']
            user_id = item.get('user_id')

            if 'photos' in item:
                for photo in item['photos']:
                    photo_record = {
                        'id': photo.get('id'),
                        'item_id': item_id,
                        'user_id': user_id,
                        'stage': photo.get('stage'),
                        'image_note': photo.get('imageNote'),
                        'file_name': photo.get('fileName'),
                        'storage_path': photo.get('gcsPath'),
                        'uploaded_at': photo.get('uploadedAt'),
                        'uploaded_timezone': photo.get('uploadedTimezone')
                    }
                    photos.append(photo_record)

        self.logger.info(f"Extracted {len(photos)} photos")
        return photos

    def validate_export(self, output_dir: str = "migration_data") -> bool:
        """
        Validate the exported data.

        Args:
            output_dir: Directory containing exported data

        Returns:
            True if validation passes
        """
        output_path = Path(output_dir)

        # Check if all files exist
        required_files = [
            "pottery_items.json",
            "photos.json",
            "export_metadata.json"
        ]

        for filename in required_files:
            filepath = output_path / filename
            if not filepath.exists():
                self.logger.error(f"Missing required file: {filepath}")
                return False

        # Load and validate data
        try:
            with open(output_path / "pottery_items.json", 'r') as f:
                items = json.load(f)

            with open(output_path / "photos.json", 'r') as f:
                photos = json.load(f)

            with open(output_path / "export_metadata.json", 'r') as f:
                metadata = json.load(f)

            # Validate counts match metadata
            if len(items) != metadata['total_items']:
                self.logger.error("Item count mismatch in metadata")
                return False

            if len(photos) != metadata['total_photos']:
                self.logger.error("Photo count mismatch in metadata")
                return False

            # Validate required fields
            for item in items:
                if not all(field in item for field in ['id', 'user_id', 'name']):
                    self.logger.error(f"Missing required fields in item: {item.get('id')}")
                    return False

            for photo in photos:
                if not all(field in photo for field in ['id', 'item_id', 'user_id']):
                    self.logger.error(f"Missing required fields in photo: {photo.get('id')}")
                    return False

            self.logger.info("Export validation passed")
            return True

        except Exception as e:
            self.logger.error(f"Validation failed: {e}")
            return False


async def main():
    """Main function to run the export."""
    logging.basicConfig(level=logging.INFO)

    exporter = FirestoreExporter()

    # Export data
    print("Starting Firestore export...")
    metadata = exporter.export_all_data()

    print(f"Export completed:")
    print(f"  - Items: {metadata['total_items']}")
    print(f"  - Photos: {metadata['total_photos']}")
    print(f"  - Files: {', '.join(metadata['files_created'])}")

    # Validate export
    print("\nValidating export...")
    if exporter.validate_export():
        print("✅ Export validation passed")
    else:
        print("❌ Export validation failed")
        return 1

    print("\n🎉 Firestore export completed successfully!")
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(asyncio.run(main()))