#!/usr/bin/env python3
"""
Data Validation Script

Validates data consistency between Firestore and Supabase during migration.
Can be used during dual-write phase to ensure data integrity.
"""

import asyncio
import logging
from datetime import datetime
from typing import Dict, List, Set

import asyncpg
from google.cloud import firestore
from supabase import create_client


class DataValidator:
    """Validates data consistency between Firestore and Supabase."""

    def __init__(
        self,
        firestore_project: str,
        firestore_database: str,
        firestore_collection: str,
        supabase_url: str,
        supabase_service_role_key: str,
        database_url: str,
    ):
        """
        Initialize validator with both database connections.

        Args:
            firestore_project: GCP project ID
            firestore_database: Firestore database ID
            firestore_collection: Firestore collection name
            supabase_url: Supabase project URL
            supabase_service_role_key: Service role key
            database_url: PostgreSQL connection URL
        """
        # Firestore client
        self.firestore_db = firestore.Client(
            project=firestore_project, database=firestore_database
        )
        self.collection_name = firestore_collection

        # Supabase client
        self.supabase_client = create_client(supabase_url, supabase_service_role_key)
        self.database_url = database_url

        self.logger = logging.getLogger(__name__)

    async def validate_all_data(self) -> Dict:
        """
        Perform comprehensive data validation between Firestore and Supabase.

        Returns:
            Dict with validation results
        """
        validation_results = {
            "timestamp": datetime.utcnow().isoformat(),
            "items_validation": await self._validate_pottery_items(),
            "photos_validation": await self._validate_photos(),
            "foreign_key_validation": await self._validate_foreign_keys(),
            "count_validation": await self._validate_counts(),
        }

        # Overall validation status
        validation_results["overall_status"] = all(
            [
                validation_results["items_validation"]["status"] == "passed",
                validation_results["photos_validation"]["status"] == "passed",
                validation_results["foreign_key_validation"]["status"] == "passed",
                validation_results["count_validation"]["status"] == "passed",
            ]
        )

        return validation_results

    async def _validate_pottery_items(self) -> Dict:
        """Validate pottery items between Firestore and Supabase."""
        self.logger.info("Validating pottery items...")

        # Get Firestore items
        firestore_items = {}
        docs = self.firestore_db.collection(self.collection_name).stream()

        for doc in docs:
            item_data = doc.to_dict()
            firestore_items[doc.id] = {
                "name": item_data["name"],
                "clay_type": item_data["clayType"],
                "glaze": item_data.get("glaze"),
                "location": item_data["location"],
                "user_id": item_data.get("user_id"),
            }

        # Get Supabase items
        conn = await asyncpg.connect(self.database_url)
        try:
            supabase_rows = await conn.fetch(
                """
                SELECT id, name, clay_type, glaze, location, user_id
                FROM pottery_items
            """
            )

            supabase_items = {
                str(row["id"]): {
                    "name": row["name"],
                    "clay_type": row["clay_type"],
                    "glaze": row["glaze"],
                    "location": row["location"],
                    "user_id": row["user_id"],
                }
                for row in supabase_rows
            }
        finally:
            await conn.close()

        # Compare data
        firestore_ids = set(firestore_items.keys())
        supabase_ids = set(supabase_items.keys())

        missing_in_supabase = firestore_ids - supabase_ids
        extra_in_supabase = supabase_ids - firestore_ids
        common_ids = firestore_ids & supabase_ids

        # Check for data differences in common items
        data_mismatches = []
        for item_id in common_ids:
            fs_item = firestore_items[item_id]
            sb_item = supabase_items[item_id]

            if fs_item != sb_item:
                data_mismatches.append(
                    {"item_id": item_id, "firestore": fs_item, "supabase": sb_item}
                )

        return {
            "status": (
                "passed"
                if not missing_in_supabase
                and not extra_in_supabase
                and not data_mismatches
                else "failed"
            ),
            "firestore_count": len(firestore_items),
            "supabase_count": len(supabase_items),
            "missing_in_supabase": list(missing_in_supabase),
            "extra_in_supabase": list(extra_in_supabase),
            "data_mismatches": data_mismatches,
        }

    async def _validate_photos(self) -> Dict:
        """Validate photos between Firestore and Supabase."""
        self.logger.info("Validating photos...")

        # Get Firestore photos (embedded in items)
        firestore_photos = {}
        docs = self.firestore_db.collection(self.collection_name).stream()

        for doc in docs:
            item_data = doc.to_dict()
            if "photos" in item_data:
                for photo in item_data["photos"]:
                    photo_id = photo.get("id")
                    if photo_id:
                        firestore_photos[photo_id] = {
                            "item_id": doc.id,
                            "stage": photo.get("stage"),
                            "image_note": photo.get("imageNote"),
                            "file_name": photo.get("fileName"),
                            "storage_path": photo.get("gcsPath"),
                            "user_id": item_data.get("user_id"),
                        }

        # Get Supabase photos
        conn = await asyncpg.connect(self.database_url)
        try:
            supabase_rows = await conn.fetch(
                """
                SELECT id, item_id, stage, image_note, file_name, storage_path, user_id
                FROM photos
            """
            )

            supabase_photos = {
                str(row["id"]): {
                    "item_id": str(row["item_id"]),
                    "stage": row["stage"],
                    "image_note": row["image_note"],
                    "file_name": row["file_name"],
                    "storage_path": row["storage_path"],
                    "user_id": row["user_id"],
                }
                for row in supabase_rows
            }
        finally:
            await conn.close()

        # Compare data
        firestore_ids = set(firestore_photos.keys())
        supabase_ids = set(supabase_photos.keys())

        missing_in_supabase = firestore_ids - supabase_ids
        extra_in_supabase = supabase_ids - firestore_ids
        common_ids = firestore_ids & supabase_ids

        # Check for data differences
        data_mismatches = []
        for photo_id in common_ids:
            fs_photo = firestore_photos[photo_id]
            sb_photo = supabase_photos[photo_id]

            if fs_photo != sb_photo:
                data_mismatches.append(
                    {"photo_id": photo_id, "firestore": fs_photo, "supabase": sb_photo}
                )

        return {
            "status": (
                "passed"
                if not missing_in_supabase
                and not extra_in_supabase
                and not data_mismatches
                else "failed"
            ),
            "firestore_count": len(firestore_photos),
            "supabase_count": len(supabase_photos),
            "missing_in_supabase": list(missing_in_supabase),
            "extra_in_supabase": list(extra_in_supabase),
            "data_mismatches": data_mismatches,
        }

    async def _validate_foreign_keys(self) -> Dict:
        """Validate foreign key relationships in Supabase."""
        self.logger.info("Validating foreign key relationships...")

        conn = await asyncpg.connect(self.database_url)
        try:
            # Check for orphaned photos
            orphaned_photos = await conn.fetch(
                """
                SELECT p.id, p.item_id
                FROM photos p
                LEFT JOIN pottery_items i ON p.item_id = i.id
                WHERE i.id IS NULL
            """
            )

            # Check for photos without items
            photos_without_items = len(orphaned_photos)

            return {
                "status": "passed" if photos_without_items == 0 else "failed",
                "orphaned_photos_count": photos_without_items,
                "orphaned_photo_ids": [str(row["id"]) for row in orphaned_photos],
            }

        finally:
            await conn.close()

    async def _validate_counts(self) -> Dict:
        """Validate record counts between databases."""
        self.logger.info("Validating record counts...")

        # Firestore counts
        firestore_items = list(
            self.firestore_db.collection(self.collection_name).stream()
        )
        firestore_item_count = len(firestore_items)

        firestore_photo_count = 0
        for doc in firestore_items:
            item_data = doc.to_dict()
            if "photos" in item_data:
                firestore_photo_count += len(item_data["photos"])

        # Supabase counts
        conn = await asyncpg.connect(self.database_url)
        try:
            supabase_item_count = await conn.fetchval(
                "SELECT COUNT(*) FROM pottery_items"
            )
            supabase_photo_count = await conn.fetchval("SELECT COUNT(*) FROM photos")
        finally:
            await conn.close()

        # Compare counts
        items_match = firestore_item_count == supabase_item_count
        photos_match = firestore_photo_count == supabase_photo_count

        return {
            "status": "passed" if items_match and photos_match else "failed",
            "firestore_items": firestore_item_count,
            "supabase_items": supabase_item_count,
            "items_match": items_match,
            "firestore_photos": firestore_photo_count,
            "supabase_photos": supabase_photo_count,
            "photos_match": photos_match,
        }

    def print_validation_report(self, results: Dict):
        """Print a human-readable validation report."""
        print(f"\n🔍 Data Validation Report - {results['timestamp']}")
        print("=" * 60)

        # Overall status
        if results["overall_status"]:
            print("✅ Overall Status: PASSED")
        else:
            print("❌ Overall Status: FAILED")

        # Items validation
        items = results["items_validation"]
        print(f"\n📦 Pottery Items:")
        print(
            f"  Status: {'✅ PASSED' if items['status'] == 'passed' else '❌ FAILED'}"
        )
        print(f"  Firestore: {items['firestore_count']} items")
        print(f"  Supabase: {items['supabase_count']} items")

        if items["missing_in_supabase"]:
            print(
                f"  ⚠️  Missing in Supabase: {len(items['missing_in_supabase'])} items"
            )

        if items["data_mismatches"]:
            print(f"  ⚠️  Data mismatches: {len(items['data_mismatches'])} items")

        # Photos validation
        photos = results["photos_validation"]
        print(f"\n📸 Photos:")
        print(
            f"  Status: {'✅ PASSED' if photos['status'] == 'passed' else '❌ FAILED'}"
        )
        print(f"  Firestore: {photos['firestore_count']} photos")
        print(f"  Supabase: {photos['supabase_count']} photos")

        if photos["missing_in_supabase"]:
            print(
                f"  ⚠️  Missing in Supabase: {len(photos['missing_in_supabase'])} photos"
            )

        # Foreign keys validation
        fks = results["foreign_key_validation"]
        print(f"\n🔗 Foreign Key Integrity:")
        print(f"  Status: {'✅ PASSED' if fks['status'] == 'passed' else '❌ FAILED'}")

        if fks["orphaned_photos_count"] > 0:
            print(f"  ⚠️  Orphaned photos: {fks['orphaned_photos_count']}")

        # Counts validation
        counts = results["count_validation"]
        print(f"\n🔢 Count Validation:")
        print(
            f"  Status: {'✅ PASSED' if counts['status'] == 'passed' else '❌ FAILED'}"
        )
        print(f"  Items match: {'✅' if counts['items_match'] else '❌'}")
        print(f"  Photos match: {'✅' if counts['photos_match'] else '❌'}")


async def main():
    """Main function to run validation."""
    import os

    from dotenv import load_dotenv

    # Load environment variables
    load_dotenv(".env.local")  # Firestore config
    load_dotenv(".env.supabase.local")  # Supabase config

    # Firestore configuration
    firestore_project = os.getenv("GCP_PROJECT_ID")
    firestore_database = os.getenv("FIRESTORE_DATABASE_ID", "(default)")
    firestore_collection = os.getenv("FIRESTORE_COLLECTION", "pottery_items")

    # Supabase configuration
    supabase_url = os.getenv("SUPABASE_URL")
    service_role_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    database_url = os.getenv("DATABASE_URL")

    if not all([firestore_project, supabase_url, service_role_key, database_url]):
        print("❌ Missing required environment variables")
        return 1

    logging.basicConfig(level=logging.INFO)

    validator = DataValidator(
        firestore_project=firestore_project,
        firestore_database=firestore_database,
        firestore_collection=firestore_collection,
        supabase_url=supabase_url,
        supabase_service_role_key=service_role_key,
        database_url=database_url,
    )

    try:
        print("🔍 Starting data validation...")
        results = await validator.validate_all_data()

        validator.print_validation_report(results)

        return 0 if results["overall_status"] else 1

    except Exception as e:
        print(f"❌ Validation failed: {e}")
        return 1


if __name__ == "__main__":
    import sys

    sys.exit(asyncio.run(main()))
