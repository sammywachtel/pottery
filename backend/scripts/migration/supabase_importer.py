#!/usr/bin/env python3
"""
Supabase Data Importer

Imports pottery items and photos from JSON exports into Supabase PostgreSQL database.
Creates the required tables and inserts data with proper foreign key relationships.
"""

import asyncio
import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, List
from uuid import UUID

import asyncpg
from supabase import create_client


class SupabaseImporter:
    """Imports data into Supabase PostgreSQL database."""

    def __init__(
        self, supabase_url: str, supabase_service_role_key: str, database_url: str
    ):
        """
        Initialize Supabase client and database connection.

        Args:
            supabase_url: Supabase project URL
            supabase_service_role_key: Service role key for admin operations
            database_url: PostgreSQL connection URL
        """
        self.supabase_client = create_client(supabase_url, supabase_service_role_key)
        self.database_url = database_url
        self.logger = logging.getLogger(__name__)

    async def create_schema(self):
        """Create the required database schema for pottery items and photos."""
        # SQL schema creation
        schema_sql = """
        -- Enable UUID extension
        CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

        -- Create pottery_items table
        CREATE TABLE IF NOT EXISTS pottery_items (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            clay_type TEXT NOT NULL,
            glaze TEXT,
            location TEXT NOT NULL,
            note TEXT,
            created_datetime TIMESTAMPTZ NOT NULL,
            created_timezone TEXT,
            measurements JSONB,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- Create photos table
        CREATE TABLE IF NOT EXISTS photos (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            item_id UUID NOT NULL REFERENCES pottery_items(id) ON DELETE CASCADE,
            user_id TEXT NOT NULL,
            stage TEXT NOT NULL,
            image_note TEXT,
            file_name TEXT,
            storage_path TEXT NOT NULL,
            uploaded_at TIMESTAMPTZ DEFAULT NOW(),
            uploaded_timezone TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- Create indexes for performance
        CREATE INDEX IF NOT EXISTS idx_pottery_items_user_id ON pottery_items(user_id);
        CREATE INDEX IF NOT EXISTS idx_pottery_items_created_at ON pottery_items(created_at);
        CREATE INDEX IF NOT EXISTS idx_photos_item_id ON photos(item_id);
        CREATE INDEX IF NOT EXISTS idx_photos_user_id ON photos(user_id);

        -- Enable Row Level Security (RLS)
        ALTER TABLE pottery_items ENABLE ROW LEVEL SECURITY;
        ALTER TABLE photos ENABLE ROW LEVEL SECURITY;

        -- RLS Policies (for future Supabase auth integration)
        DROP POLICY IF EXISTS "Users can only access their own items" ON pottery_items;
        CREATE POLICY "Users can only access their own items" ON pottery_items
            FOR ALL USING (auth.uid()::text = user_id);

        DROP POLICY IF EXISTS "Users can only access their own photos" ON photos;
        CREATE POLICY "Users can only access their own photos" ON photos
            FOR ALL USING (auth.uid()::text = user_id);
        """

        conn = await asyncpg.connect(self.database_url)
        try:
            await conn.execute(schema_sql)
            self.logger.info("Database schema created successfully")
        finally:
            await conn.close()

    async def import_data(self, data_dir: str = "migration_data") -> Dict:
        """
        Import pottery items and photos from JSON files.

        Args:
            data_dir: Directory containing exported JSON files

        Returns:
            Dict with import statistics
        """
        data_path = Path(data_dir)

        # Load exported data
        with open(data_path / "pottery_items.json", "r") as f:
            items_data = json.load(f)

        with open(data_path / "photos.json", "r") as f:
            photos_data = json.load(f)

        # Import items first (photos reference items)
        items_imported = await self._import_pottery_items(items_data)

        # Import photos
        photos_imported = await self._import_photos(photos_data)

        # Create import metadata
        metadata = {
            "import_timestamp": datetime.utcnow().isoformat(),
            "target_database": "supabase",
            "items_imported": items_imported,
            "photos_imported": photos_imported,
            "source_items": len(items_data),
            "source_photos": len(photos_data),
        }

        self.logger.info(
            f"Import completed: {items_imported} items, " f"{photos_imported} photos"
        )

        return metadata

    async def _import_pottery_items(self, items_data: List[Dict]) -> int:
        """Import pottery items into Supabase."""
        conn = await asyncpg.connect(self.database_url)
        imported_count = 0

        try:
            for item in items_data:
                try:
                    # Prepare item data for PostgreSQL
                    item_record = {
                        "id": item["id"],
                        "user_id": item.get("user_id"),
                        "name": item["name"],
                        "clay_type": item["clayType"],
                        "glaze": item.get("glaze"),
                        "location": item["location"],
                        "note": item.get("note"),
                        "created_datetime": item["createdDateTime"],
                        "created_timezone": item.get("createdTimezone"),
                        "measurements": (
                            json.dumps(item.get("measurements"))
                            if item.get("measurements")
                            else None
                        ),
                    }

                    # Insert using raw SQL for better control
                    await conn.execute(
                        """
                        INSERT INTO pottery_items (
                            id, user_id, name, clay_type, glaze, location, note,
                            created_datetime, created_timezone, measurements
                        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
                        ON CONFLICT (id) DO UPDATE SET
                            name = EXCLUDED.name,
                            clay_type = EXCLUDED.clay_type,
                            glaze = EXCLUDED.glaze,
                            location = EXCLUDED.location,
                            note = EXCLUDED.note,
                            updated_at = NOW()
                    """,
                        item_record["id"],
                        item_record["user_id"],
                        item_record["name"],
                        item_record["clay_type"],
                        item_record["glaze"],
                        item_record["location"],
                        item_record["note"],
                        item_record["created_datetime"],
                        item_record["created_timezone"],
                        item_record["measurements"],
                    )

                    imported_count += 1

                except Exception as e:
                    self.logger.error(f"Failed to import item {item.get('id')}: {e}")

        finally:
            await conn.close()

        self.logger.info(f"Imported {imported_count} pottery items")
        return imported_count

    async def _import_photos(self, photos_data: List[Dict]) -> int:
        """Import photos into Supabase."""
        conn = await asyncpg.connect(self.database_url)
        imported_count = 0

        try:
            for photo in photos_data:
                try:
                    # Insert photo record
                    await conn.execute(
                        """
                        INSERT INTO photos (
                            id, item_id, user_id, stage, image_note, file_name,
                            storage_path, uploaded_at, uploaded_timezone
                        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
                        ON CONFLICT (id) DO UPDATE SET
                            stage = EXCLUDED.stage,
                            image_note = EXCLUDED.image_note,
                            file_name = EXCLUDED.file_name,
                            storage_path = EXCLUDED.storage_path,
                            updated_at = NOW()
                    """,
                        photo["id"],
                        photo["item_id"],
                        photo["user_id"],
                        photo["stage"],
                        photo.get("image_note"),
                        photo.get("file_name"),
                        photo["storage_path"],
                        photo["uploaded_at"],
                        photo.get("uploaded_timezone"),
                    )

                    imported_count += 1

                except Exception as e:
                    self.logger.error(f"Failed to import photo {photo.get('id')}: {e}")

        finally:
            await conn.close()

        self.logger.info(f"Imported {imported_count} photos")
        return imported_count

    async def validate_import(self) -> bool:
        """
        Validate the imported data in Supabase.

        Returns:
            True if validation passes
        """
        conn = await asyncpg.connect(self.database_url)

        try:
            # Check table exists and has data
            items_count = await conn.fetchval("SELECT COUNT(*) FROM pottery_items")
            photos_count = await conn.fetchval("SELECT COUNT(*) FROM photos")

            self.logger.info(
                f"Found {items_count} items and {photos_count} photos in database"
            )

            # Check foreign key integrity
            orphaned_photos = await conn.fetchval(
                """
                SELECT COUNT(*) FROM photos p
                LEFT JOIN pottery_items i ON p.item_id = i.id
                WHERE i.id IS NULL
            """
            )

            if orphaned_photos > 0:
                self.logger.error(f"Found {orphaned_photos} orphaned photos")
                return False

            # Check required fields
            items_missing_required = await conn.fetchval(
                """
                SELECT COUNT(*) FROM pottery_items
                WHERE name IS NULL OR clay_type IS NULL OR location IS NULL OR user_id IS NULL
            """
            )

            if items_missing_required > 0:
                self.logger.error(
                    f"Found {items_missing_required} items with missing required fields"
                )
                return False

            photos_missing_required = await conn.fetchval(
                """
                SELECT COUNT(*) FROM photos
                WHERE item_id IS NULL OR user_id IS NULL OR stage IS NULL OR storage_path IS NULL
            """
            )

            if photos_missing_required > 0:
                self.logger.error(
                    f"Found {photos_missing_required} photos with missing required fields"
                )
                return False

            self.logger.info("Import validation passed")
            return True

        except Exception as e:
            self.logger.error(f"Validation failed: {e}")
            return False

        finally:
            await conn.close()


async def main():
    """Main function to run the import."""
    import os

    from dotenv import load_dotenv

    # Load environment variables
    load_dotenv(".env.supabase.local")  # or appropriate env file

    supabase_url = os.getenv("SUPABASE_URL")
    service_role_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    database_url = os.getenv("DATABASE_URL")

    if not all([supabase_url, service_role_key, database_url]):
        print("❌ Missing required environment variables")
        return 1

    logging.basicConfig(level=logging.INFO)

    importer = SupabaseImporter(supabase_url, service_role_key, database_url)

    try:
        # Create schema
        print("Creating database schema...")
        await importer.create_schema()

        # Import data
        print("Starting data import...")
        metadata = await importer.import_data()

        print(f"Import completed:")
        print(f"  - Items: {metadata['items_imported']}/{metadata['source_items']}")
        print(f"  - Photos: {metadata['photos_imported']}/{metadata['source_photos']}")

        # Validate import
        print("\nValidating import...")
        if await importer.validate_import():
            print("✅ Import validation passed")
        else:
            print("❌ Import validation failed")
            return 1

        print("\n🎉 Supabase import completed successfully!")
        return 0

    except Exception as e:
        print(f"❌ Import failed: {e}")
        return 1


if __name__ == "__main__":
    import sys

    sys.exit(asyncio.run(main()))
