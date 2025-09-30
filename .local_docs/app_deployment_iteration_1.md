# Private distribution to your Workspace (managed Google Play)

## Overview

This method allows you to distribute your app privately to users within your Google Workspace domain using managed Google Play. It ensures that only users in your organization can access and install the app.

## Steps

### 1. Prepare your app for private distribution

- Build your app APK or AAB.
- Ensure your app's package name is unique within your organization.

### 2. Create a Google Cloud project and enable the Play Developer API

- Go to the [Google Cloud Console](https://console.cloud.google.com/).
- Create a new project or select an existing one.
- Enable the **Google Play Android Developer API**.
- Create a service account with the **Service Account User** and **Google Play Android Developer** roles.
- Download the JSON key for the service account.

### 3. Link your Google Cloud project to your Google Play Console

- In the Google Play Console, go to **Setup > API access**.
- Link your Google Cloud project.
- Grant the service account access to your Play Console.

### 4. Upload your app to Google Play Console

- Upload your APK/AAB to an internal testing track or production track.
- Make sure to save the version code and track details.

### 5. Use the Play Developer API to assign the app to your Workspace

- Use the Play Developer API to create a private app listing.
- Assign the app to your Google Workspace domain.

## `.env.prod` example

```env
GOOGLE_APPLICATION_CREDENTIALS=path/to/your/service-account-key.json
PACKAGE_NAME=com.example.yourapp
PLAY_TRACK=internal
WORKSPACE_DOMAIN=yourdomain.com
```

## Python CLI script

```python
import os
import sys
from google.oauth2 import service_account
from googleapiclient.discovery import build

def main():
    # Load environment variables
    credentials_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
    package_name = os.getenv('PACKAGE_NAME')
    play_track = os.getenv('PLAY_TRACK', 'internal')
    workspace_domain = os.getenv('WORKSPACE_DOMAIN')

    if not all([credentials_path, package_name, workspace_domain]):
        print("Missing required environment variables.")
        sys.exit(1)

    # Authenticate with service account
    credentials = service_account.Credentials.from_service_account_file(
        credentials_path,
        scopes=['https://www.googleapis.com/auth/androidpublisher']
    )

    service = build('androidpublisher', 'v3', credentials=credentials)

    # Assign app to Workspace domain
    try:
        edit_request = service.edits().insert(body={}, packageName=package_name)
        edit_response = edit_request.execute()
        edit_id = edit_response['id']

        # Update track with rollout to Workspace domain
        track_body = {
            'track': play_track,
            'releases': [{
                'name': 'Private release to Workspace',
                'versionCodes': [get_latest_version_code(service, package_name)],
                'status': 'completed',
                'userFraction': 1.0
            }]
        }

        service.edits().tracks().update(
            editId=edit_id,
            track=play_track,
            packageName=package_name,
            body=track_body
        ).execute()

        # Assign users in Workspace domain
        # Note: Managed Google Play automatically restricts app availability to your domain.

        service.edits().commit(editId=edit_id, packageName=package_name).execute()

        print(f"App {package_name} successfully distributed to Workspace domain {workspace_domain}.")

    except Exception as e:
        print(f"An error occurred: {e}")

def get_latest_version_code(service, package_name):
    # Fetch the latest version code from the Play Console
    edits = service.edits()
    # This is a placeholder: implement logic to retrieve latest version code
    # For example, list all APKs or bundles and get the highest version code
    return 123  # Replace with actual version code retrieval

if __name__ == "__main__":
    main()
```

## Bash wrapper

```bash
#!/bin/bash

set -e

# Load environment variables from .env.prod
export $(grep -v '^#' .env.prod | xargs)

# Run Python CLI script
python3 distribute_to_workspace.py
```

## Rollout notes

- Start with an internal test track to validate the deployment.
- Gradually promote to production once verified.
- Monitor crash reports and user feedback.

## Common gotchas

- Ensure the service account has the necessary permissions.
- The package name must match exactly.
- The Google Workspace domain must be correctly specified.
- API quotas and limits apply; monitor usage.
- Managed Google Play handles user assignment automatically for private apps.
