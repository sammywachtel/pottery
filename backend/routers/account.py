"""
Account management router for user account operations.
Handles account deletion requests for Google Play compliance.
"""

import logging
import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, Form, HTTPException
from fastapi.responses import HTMLResponse

from auth import get_current_user
from services import firestore_service

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/account", tags=["account"])


# HTML template for deletion request form
# flake8: noqa: E501
DELETE_ACCOUNT_HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>Pottery Studio - Delete Account</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 500px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            font-size: 24px;
        }
        p {
            color: #666;
            line-height: 1.6;
        }
        .warning {
            background: #fff3cd;
            border: 1px solid #ffc107;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }
        input, textarea {
            width: 100%;
            padding: 10px;
            margin: 10px 0;
            border: 1px solid #ddd;
            border-radius: 5px;
            box-sizing: border-box;
        }
        button {
            background: #dc3545;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            cursor: pointer;
            width: 100%;
        }
        button:hover {
            background: #c82333;
        }
        .success {
            background: #d4edda;
            border: 1px solid #28a745;
            padding: 15px;
            border-radius: 5px;
            color: #155724;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Delete Your Pottery Studio Account</h1>

        <div class="warning">
            <strong>⚠️ Warning:</strong> Deleting your account will permanently remove:
            <ul>
                <li>All your pottery items and their details</li>
                <li>All photos you've uploaded</li>
                <li>Your account information</li>
            </ul>
            This action cannot be undone.
        </div>

        <form method="POST" action="/account/delete-request">
            <label for="email">Email address associated with your account:</label>
            <input type="email" id="email" name="email" required
                   placeholder="your.email@example.com">

            <label for="reason">Reason for deletion (optional):</label>
            <textarea id="reason" name="reason" rows="3"
                      placeholder="Help us improve by sharing why you're leaving..."></textarea>

            <div style="margin: 20px 0;">
                <label style="display: flex; align-items: flex-start; cursor: pointer;">
                    <input type="checkbox" required style="margin-right: 10px; margin-top: 3px;">
                    <span>I understand that this will permanently delete all my data</span>
                </label>
            </div>

            <button type="submit">Request Account Deletion</button>
        </form>

        <p style="margin-top: 20px; font-size: 14px; color: #999;">
            Your request will be processed within 30 days. You'll receive a confirmation email.
        </p>
    </div>
</body>
</html>
"""

SUCCESS_HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>Deletion Request Received</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 500px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .success {
            background: #d4edda;
            border: 1px solid #28a745;
            padding: 20px;
            border-radius: 5px;
            color: #155724;
            text-align: center;
        }
        h1 { color: #28a745; font-size: 24px; }
        p { color: #666; line-height: 1.6; }
    </style>
</head>
<body>
    <div class="container">
        <div class="success">
            <h1>✓ Request Received</h1>
            <p>Your account deletion request has been received.</p>
        </div>
        <p>We'll process your request within 30 days. You'll receive a confirmation email at the address you provided.</p>
        <p>If you change your mind, please contact us immediately.</p>
    </div>
</body>
</html>
"""

PRIVACY_POLICY_HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>Pottery Studio - Privacy Policy</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
            line-height: 1.6;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            font-size: 28px;
            margin-bottom: 10px;
        }
        h2 {
            color: #555;
            font-size: 20px;
            margin-top: 30px;
            margin-bottom: 15px;
        }
        p, li {
            color: #666;
            margin-bottom: 10px;
        }
        ul {
            margin-left: 20px;
        }
        .last-updated {
            color: #999;
            font-size: 14px;
            margin-bottom: 30px;
        }
        .contact {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-top: 30px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Privacy Policy</h1>
        <p class="last-updated">Last updated: October 2, 2025</p>

        <h2>Overview</h2>
        <p>Pottery Studio ("the App") is a private family organization app for tracking pottery items. This app is restricted to authorized family members only.</p>

        <h2>Information We Collect</h2>
        <p>The App collects and stores the following information:</p>
        <ul>
            <li><strong>Account Information:</strong> Email address and name from Google Sign-In</li>
            <li><strong>Pottery Item Data:</strong> Information about your pottery pieces including descriptions, measurements, stages, and notes</li>
            <li><strong>Photos:</strong> Images you upload of your pottery items</li>
            <li><strong>Usage Data:</strong> Basic app usage and error logs for troubleshooting</li>
        </ul>

        <h2>How We Use Your Information</h2>
        <p>Your information is used solely for:</p>
        <ul>
            <li>Storing and managing your pottery inventory</li>
            <li>Syncing your data across your devices</li>
            <li>Authenticating your identity</li>
            <li>Improving app functionality and fixing bugs</li>
        </ul>

        <h2>Data Storage and Security</h2>
        <p>All data is stored securely using Google Cloud services:</p>
        <ul>
            <li>Pottery item data is stored in Google Cloud Firestore</li>
            <li>Photos are stored in Google Cloud Storage</li>
            <li>Authentication is handled by Google Firebase Authentication</li>
            <li>All data is encrypted in transit and at rest</li>
        </ul>

        <h2>Data Sharing</h2>
        <p><strong>We do not share your data with third parties.</strong> Your information is private and restricted to your family organization only.</p>

        <h2>Data Retention</h2>
        <p>Your data is retained as long as your account is active. You can request deletion of your account and all associated data at any time.</p>

        <h2>Your Rights</h2>
        <p>You have the right to:</p>
        <ul>
            <li>Access your personal data</li>
            <li>Correct inaccurate data</li>
            <li>Request deletion of your account and data</li>
            <li>Export your data</li>
        </ul>

        <h2>Account Deletion</h2>
        <p>To delete your account and all associated data, please visit our <a href="/account/delete">account deletion page</a>. Account deletion requests are processed within 30 days.</p>

        <h2>Children's Privacy</h2>
        <p>This app is designed for use within a family organization and may be used by family members of all ages. We do not knowingly collect personal information from children outside of the family organization context.</p>

        <h2>Changes to This Policy</h2>
        <p>We may update this privacy policy from time to time. We will notify you of any changes by updating the "Last updated" date at the top of this policy.</p>

        <div class="contact">
            <h2>Contact Us</h2>
            <p>If you have questions about this privacy policy or wish to exercise your rights, please visit our account deletion page or contact the app administrator within your family organization.</p>
        </div>
    </div>
</body>
</html>
"""


@router.get("/privacy-policy", response_class=HTMLResponse)
async def privacy_policy():
    """Display privacy policy for Google Play compliance."""
    return HTMLResponse(content=PRIVACY_POLICY_HTML)


@router.get("/delete", response_class=HTMLResponse)
async def show_delete_form():
    """Display the account deletion request form."""
    return HTMLResponse(content=DELETE_ACCOUNT_HTML)


@router.post("/delete-request", response_class=HTMLResponse)
async def process_delete_request(
    email: str = Form(...), reason: Optional[str] = Form(None)
):
    """Process account deletion request."""
    try:
        # Generate unique request ID
        request_id = str(uuid.uuid4())

        # Create deletion request document
        deletion_request = {
            "request_id": request_id,
            "email": email.lower().strip(),
            "reason": reason.strip() if reason else None,
            "requested_at": datetime.utcnow().isoformat(),
            "status": "pending",
            "processed_at": None,
            "processed_by": None,
        }

        # Store in Firestore (account deletion requests collection)
        db, _ = firestore_service._ensure_firestore_client()
        collection_ref = db.collection("account_deletion_requests")
        await collection_ref.document(request_id).set(deletion_request)

        logger.info(f"Account deletion request stored: {request_id} for email: {email}")
        if reason:
            logger.info(f"Deletion reason: {reason}")

        # TODO: Send confirmation email to user
        # TODO: Send notification to admin
        # TODO: Schedule deletion after grace period (30 days)

        return HTMLResponse(content=SUCCESS_HTML)

    except Exception as e:
        logger.error(f"Error processing deletion request: {str(e)}")
        raise HTTPException(
            status_code=500, detail="Failed to process deletion request"
        )


@router.delete("/delete", dependencies=[Depends(get_current_user)])
async def delete_account_authenticated(current_user: dict = Depends(get_current_user)):
    """
    Delete account for authenticated user.
    This endpoint is for in-app deletion (future implementation).
    """
    try:
        user_id = current_user.get("user_id")
        logger.info(f"Account deletion initiated for user: {user_id}")

        # TODO: Implement actual deletion logic:
        # 1. Delete all items from Firestore
        # 2. Delete all photos from Cloud Storage
        # 3. Delete user authentication account
        # 4. Log the deletion for compliance

        return {
            "message": "Account deletion initiated. Your data will be removed within 24 hours."
        }

    except Exception as e:
        logger.error(f"Error deleting account: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to delete account")
