#!/usr/bin/env python3

"""
Upload Pottery Studio app to Google Play Store

This script uploads an AAB or APK to the specified release track using the
Google Play Developer API.

Environment Variables:
    GOOGLE_APPLICATION_CREDENTIALS: Path to service account JSON key
    PACKAGE_NAME: Android package name (e.g., com.pottery.app)
    BUILD_FILE: Path to AAB or APK file
    PLAY_TRACK: Release track (internal, alpha, beta, production)
    RELEASE_NAME: Optional release name (default: auto-generated)
    RELEASE_NOTES: Optional release notes (default: auto-generated)

Usage:
    export GOOGLE_APPLICATION_CREDENTIALS=~/pottery-keystore/play-console-sa-key.json
    export PACKAGE_NAME=com.pottery.app
    export BUILD_FILE=build/app/outputs/bundle/prodRelease/app-prod-release.aab
    export PLAY_TRACK=internal
    python3 upload-to-play-store.py
"""

import os
import sys
from pathlib import Path
from datetime import datetime
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload


def log_info(message):
    """Opening move: Print info message"""
    print(f"\033[0;34m[INFO]\033[0m {message}")


def log_success(message):
    """Main play: Print success message"""
    print(f"\033[0;32m[SUCCESS]\033[0m {message}")


def log_error(message):
    """Time to tackle the tricky bit: Print error message"""
    print(f"\033[0;31m[ERROR]\033[0m {message}", file=sys.stderr)


def validate_environment():
    """
    Victory lap: Validate all required environment variables

    Returns:
        dict: Configuration dictionary if valid
    Raises:
        SystemExit: If any required variables are missing
    """
    required_vars = {
        'GOOGLE_APPLICATION_CREDENTIALS': 'Service account JSON key path',
        'PACKAGE_NAME': 'Android package name',
        'BUILD_FILE': 'Path to AAB or APK file',
        'PLAY_TRACK': 'Release track'
    }

    config = {}
    missing = []

    for var, description in required_vars.items():
        value = os.getenv(var)
        if not value:
            missing.append(f"{var} ({description})")
        else:
            config[var.lower()] = value

    if missing:
        log_error("Missing required environment variables:")
        for var in missing:
            log_error(f"  - {var}")
        sys.exit(1)

    # Validate files exist
    if not Path(config['google_application_credentials']).exists():
        log_error(f"Service account key not found: {config['google_application_credentials']}")
        sys.exit(1)

    if not Path(config['build_file']).exists():
        log_error(f"Build file not found: {config['build_file']}")
        sys.exit(1)

    # Validate track
    valid_tracks = ['internal', 'alpha', 'beta', 'production']
    if config['play_track'] not in valid_tracks:
        log_error(f"Invalid track: {config['play_track']}. Must be one of: {', '.join(valid_tracks)}")
        sys.exit(1)

    # Optional variables
    config['release_name'] = os.getenv('RELEASE_NAME', f"Release {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    config['release_notes'] = os.getenv('RELEASE_NOTES', "Automated release via deployment script")

    return config


def get_version_code_from_file(build_file):
    """
    Extract version code from APK/AAB filename or use placeholder

    Args:
        build_file: Path to build file

    Returns:
        int: Version code (or 1 if cannot determine)
    """
    # This is a placeholder - in production, you'd use aapt or a proper parser
    # For now, we'll let the API determine the version code from the uploaded file
    return None


def upload_to_play_store(config):
    """
    Main play: Upload app bundle to Google Play Store

    Args:
        config: Configuration dictionary

    Returns:
        bool: True if successful, False otherwise
    """
    try:
        log_info("Authenticating with Google Play API...")

        # Authenticate
        credentials = service_account.Credentials.from_service_account_file(
            config['google_application_credentials'],
            scopes=['https://www.googleapis.com/auth/androidpublisher']
        )

        service = build('androidpublisher', 'v3', credentials=credentials)

        package_name = config['package_name']
        track = config['play_track']
        build_file = config['build_file']

        log_success("Authenticated successfully")

        # Create edit
        log_info("Creating new edit...")
        edit_request = service.edits().insert(body={}, packageName=package_name)
        edit_response = edit_request.execute()
        edit_id = edit_response['id']

        log_success(f"Created edit: {edit_id}")

        # Upload bundle or APK
        log_info(f"Uploading {Path(build_file).name}...")

        # Determine if AAB or APK
        file_ext = Path(build_file).suffix.lower()

        if file_ext == '.aab':
            # Upload as bundle
            media = MediaFileUpload(build_file, mimetype='application/octet-stream', resumable=True)
            bundle_response = service.edits().bundles().upload(
                editId=edit_id,
                packageName=package_name,
                media_body=media
            ).execute()

            version_code = bundle_response['versionCode']
            log_success(f"Uploaded bundle with version code: {version_code}")

        elif file_ext == '.apk':
            # Upload as APK
            media = MediaFileUpload(build_file, mimetype='application/vnd.android.package-archive', resumable=True)
            apk_response = service.edits().apks().upload(
                editId=edit_id,
                packageName=package_name,
                media_body=media
            ).execute()

            version_code = apk_response['versionCode']
            log_success(f"Uploaded APK with version code: {version_code}")

        else:
            log_error(f"Unsupported file type: {file_ext}. Must be .aab or .apk")
            return False

        # Update track
        log_info(f"Assigning to {track} track...")

        track_body = {
            'releases': [{
                'name': config['release_name'],
                'versionCodes': [version_code],
                'status': 'completed',
                'releaseNotes': [{
                    'language': 'en-US',
                    'text': config['release_notes']
                }]
            }]
        }

        service.edits().tracks().update(
            editId=edit_id,
            track=track,
            packageName=package_name,
            body=track_body
        ).execute()

        log_success(f"Assigned to {track} track")

        # Commit changes
        log_info("Committing changes...")
        service.edits().commit(editId=edit_id, packageName=package_name).execute()

        log_success("Changes committed successfully")

        return True

    except HttpError as e:
        log_error(f"HTTP error occurred: {e}")
        if e.resp.status == 401:
            log_error("Authentication failed. Check service account permissions in Play Console.")
        elif e.resp.status == 403:
            log_error("Permission denied. Ensure service account has 'Release Manager' role.")
        elif e.resp.status == 404:
            log_error("App not found. Verify package name and ensure app exists in Play Console.")
        else:
            log_error(f"Error details: {e.content}")
        return False

    except Exception as e:
        log_error(f"Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """
    Victory lap: Main entry point
    """
    log_info("🚀 Starting Play Store upload...")

    # Validate environment
    config = validate_environment()

    log_info("Configuration:")
    print(f"  Package: {config['package_name']}")
    print(f"  Build file: {config['build_file']}")
    print(f"  Track: {config['play_track']}")
    print(f"  Release name: {config['release_name']}")
    print("")

    # Upload to Play Store
    success = upload_to_play_store(config)

    if success:
        log_success("✅ Upload completed successfully!")
        print("")
        print("Next steps:")
        print(f"  1. Visit Play Console: https://play.google.com/console")
        print(f"  2. Review the {config['play_track']} track release")
        print("  3. Roll out to users or promote to next track")
        print("")
        sys.exit(0)
    else:
        log_error("❌ Upload failed")
        sys.exit(1)


if __name__ == "__main__":
    main()
