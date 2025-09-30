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
