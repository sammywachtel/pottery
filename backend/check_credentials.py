#!/usr/bin/env python3
"""
Quick script to check if Google Cloud credentials are properly configured
"""
import os
import sys
from pathlib import Path

# Load test environment
from dotenv import load_dotenv
load_dotenv('.env.test')

print("🔍 Checking Google Cloud Credentials Configuration")
print("=" * 60)

# Check environment variables
print("\n📋 Environment Variables:")
gcp_project = os.getenv('GCP_PROJECT_ID')
gcs_bucket = os.getenv('GCS_BUCKET_NAME')
host_key_path = os.getenv('HOST_KEY_PATH')
google_creds = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')

print(f"GCP_PROJECT_ID: {gcp_project}")
print(f"GCS_BUCKET_NAME: {gcs_bucket}")
print(f"HOST_KEY_PATH: {host_key_path}")
print(f"GOOGLE_APPLICATION_CREDENTIALS: {google_creds}")

# Check if service account key exists
print("\n🔑 Service Account Key Check:")
if host_key_path:
    key_path = Path(host_key_path)
    if key_path.exists():
        print(f"✅ Key file exists at: {host_key_path}")
    else:
        print(f"❌ Key file NOT FOUND at: {host_key_path}")
        print(f"   Please ensure the service account key is at this location")
else:
    print("❌ HOST_KEY_PATH not set in .env.test")

if google_creds:
    creds_path = Path(google_creds)
    if creds_path.exists():
        print(f"✅ GOOGLE_APPLICATION_CREDENTIALS points to existing file: {google_creds}")
    else:
        print(f"❌ GOOGLE_APPLICATION_CREDENTIALS file NOT FOUND: {google_creds}")
else:
    print("⚠️  GOOGLE_APPLICATION_CREDENTIALS not set")
    print("   Set it with: export GOOGLE_APPLICATION_CREDENTIALS='/path/to/key.json'")

# Try to authenticate
print("\n🔐 Testing Authentication:")
try:
    from google.cloud import firestore
    from google.auth.exceptions import DefaultCredentialsError

    try:
        # Try to create a client
        client = firestore.Client(
            project=gcp_project,
            database=os.getenv('FIRESTORE_DATABASE_ID', '(default)')
        )
        print("✅ Successfully authenticated with Google Cloud!")
        print("   Integration tests should run normally")
    except DefaultCredentialsError as e:
        print("❌ Authentication failed: No credentials found")
        print("   Integration tests will be SKIPPED")
        print(f"\n   To fix this, either:")
        print(f"   1. Set GOOGLE_APPLICATION_CREDENTIALS:")
        print(f"      export GOOGLE_APPLICATION_CREDENTIALS='{host_key_path}'")
        print(f"   2. Or authenticate with gcloud:")
        print(f"      gcloud auth application-default login")
except ImportError:
    print("❌ google-cloud-firestore not installed")

print("\n" + "=" * 60)
print("Done!")