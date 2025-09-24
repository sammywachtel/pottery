#!/usr/bin/env python3
"""
Migration Orchestrator

Main script to orchestrate the complete migration from Firestore to Supabase.
Provides step-by-step migration with validation and rollback capabilities.
"""

import asyncio
import logging
import os
import sys
from pathlib import Path

from dotenv import load_dotenv

# Add parent directory to path to import migration modules
sys.path.append(str(Path(__file__).parent))

from migration.data_validator import DataValidator
from migration.firestore_exporter import FirestoreExporter
from migration.supabase_importer import SupabaseImporter


class MigrationOrchestrator:
    """Orchestrates the complete migration process."""

    def __init__(self):
        """Initialize the migration orchestrator."""
        self.logger = logging.getLogger(__name__)

        # Load environment variables
        load_dotenv(".env.local")  # Firestore config
        load_dotenv(".env.supabase.local")  # Supabase config

        # Firestore configuration
        self.firestore_project = os.getenv("GCP_PROJECT_ID")
        self.firestore_database = os.getenv("FIRESTORE_DATABASE_ID", "(default)")
        self.firestore_collection = os.getenv("FIRESTORE_COLLECTION", "pottery_items")

        # Supabase configuration
        self.supabase_url = os.getenv("SUPABASE_URL")
        self.service_role_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
        self.database_url = os.getenv("DATABASE_URL")

        # Migration data directory
        self.data_dir = "migration_data"

        self._validate_config()

    def _validate_config(self):
        """Validate that all required configuration is present."""
        required_vars = [
            ("GCP_PROJECT_ID", self.firestore_project),
            ("SUPABASE_URL", self.supabase_url),
            ("SUPABASE_SERVICE_ROLE_KEY", self.service_role_key),
            ("DATABASE_URL", self.database_url),
        ]

        missing_vars = [name for name, value in required_vars if not value]

        if missing_vars:
            self.logger.error(
                f"Missing required environment variables: {', '.join(missing_vars)}"
            )
            raise ValueError(f"Missing configuration: {missing_vars}")

        self.logger.info("Configuration validated successfully")

    async def run_complete_migration(self) -> bool:
        """
        Run the complete migration process.

        Returns:
            True if migration completed successfully
        """
        try:
            print("🚀 Starting Complete Migration from Firestore to Supabase")
            print("=" * 60)

            # Step 1: Export from Firestore
            if not await self._step_export_firestore():
                return False

            # Step 2: Create Supabase Schema
            if not await self._step_create_supabase_schema():
                return False

            # Step 3: Import to Supabase
            if not await self._step_import_to_supabase():
                return False

            # Step 4: Validate Migration
            if not await self._step_validate_migration():
                return False

            print("\n🎉 Migration completed successfully!")
            print("\n📋 Next Steps:")
            print("1. Test your application with Supabase")
            print("2. Update your environment configuration")
            print("3. Deploy to development environment")
            print("4. Run integration tests")

            return True

        except Exception as e:
            self.logger.error(f"Migration failed: {e}")
            print(f"\n❌ Migration failed: {e}")
            return False

    async def _step_export_firestore(self) -> bool:
        """Step 1: Export data from Firestore."""
        print("\n📤 Step 1: Exporting data from Firestore...")

        try:
            exporter = FirestoreExporter()
            metadata = exporter.export_all_data(self.data_dir)

            print(f"✅ Export completed:")
            print(f"   - Items: {metadata['total_items']}")
            print(f"   - Photos: {metadata['total_photos']}")

            # Validate export
            if not exporter.validate_export(self.data_dir):
                print("❌ Export validation failed")
                return False

            print("✅ Export validation passed")
            return True

        except Exception as e:
            self.logger.error(f"Firestore export failed: {e}")
            print(f"❌ Firestore export failed: {e}")
            return False

    async def _step_create_supabase_schema(self) -> bool:
        """Step 2: Create Supabase database schema."""
        print("\n🗄️  Step 2: Creating Supabase database schema...")

        try:
            importer = SupabaseImporter(
                self.supabase_url, self.service_role_key, self.database_url
            )

            await importer.create_schema()
            print("✅ Database schema created successfully")
            return True

        except Exception as e:
            self.logger.error(f"Schema creation failed: {e}")
            print(f"❌ Schema creation failed: {e}")
            return False

    async def _step_import_to_supabase(self) -> bool:
        """Step 3: Import data to Supabase."""
        print("\n📥 Step 3: Importing data to Supabase...")

        try:
            importer = SupabaseImporter(
                self.supabase_url, self.service_role_key, self.database_url
            )

            metadata = await importer.import_data(self.data_dir)

            print(f"✅ Import completed:")
            print(
                f"   - Items: {metadata['items_imported']}/{metadata['source_items']}"
            )
            print(
                f"   - Photos: {metadata['photos_imported']}/{metadata['source_photos']}"
            )

            # Validate import
            if not await importer.validate_import():
                print("❌ Import validation failed")
                return False

            print("✅ Import validation passed")
            return True

        except Exception as e:
            self.logger.error(f"Supabase import failed: {e}")
            print(f"❌ Supabase import failed: {e}")
            return False

    async def _step_validate_migration(self) -> bool:
        """Step 4: Validate complete migration."""
        print("\n🔍 Step 4: Validating migration data integrity...")

        try:
            validator = DataValidator(
                firestore_project=self.firestore_project,
                firestore_database=self.firestore_database,
                firestore_collection=self.firestore_collection,
                supabase_url=self.supabase_url,
                supabase_service_role_key=self.service_role_key,
                database_url=self.database_url,
            )

            results = await validator.validate_all_data()
            validator.print_validation_report(results)

            if results["overall_status"]:
                print("✅ Migration validation passed")
                return True
            else:
                print("❌ Migration validation failed")
                return False

        except Exception as e:
            self.logger.error(f"Migration validation failed: {e}")
            print(f"❌ Migration validation failed: {e}")
            return False

    async def run_validation_only(self) -> bool:
        """Run only the validation step (useful during dual-write phase)."""
        print("🔍 Running Data Validation Only...")
        return await self._step_validate_migration()

    async def run_export_only(self) -> bool:
        """Run only the export step."""
        print("📤 Running Firestore Export Only...")
        return await self._step_export_firestore()

    async def run_import_only(self) -> bool:
        """Run only the import step (requires existing export data)."""
        print("📥 Running Supabase Import Only...")

        # Check if export data exists
        data_path = Path(self.data_dir)
        if not (data_path / "pottery_items.json").exists():
            print("❌ No export data found. Run export first.")
            return False

        if not await self._step_create_supabase_schema():
            return False

        return await self._step_import_to_supabase()


async def main():
    """Main function with command-line interface."""
    import argparse

    parser = argparse.ArgumentParser(description="Firestore to Supabase Migration Tool")
    parser.add_argument(
        "command",
        choices=["migrate", "export", "import", "validate"],
        help="Migration command to run",
    )
    parser.add_argument(
        "--log-level",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        default="INFO",
        help="Set logging level",
    )

    args = parser.parse_args()

    # Configure logging
    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )

    try:
        orchestrator = MigrationOrchestrator()

        # Run specified command
        if args.command == "migrate":
            success = await orchestrator.run_complete_migration()
        elif args.command == "export":
            success = await orchestrator.run_export_only()
        elif args.command == "import":
            success = await orchestrator.run_import_only()
        elif args.command == "validate":
            success = await orchestrator.run_validation_only()
        else:
            print(f"Unknown command: {args.command}")
            return 1

        return 0 if success else 1

    except Exception as e:
        print(f"❌ Migration tool failed: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
