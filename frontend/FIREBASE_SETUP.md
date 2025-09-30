# Firebase Authentication Setup

This document outlines the steps needed to configure Firebase Authentication for the pottery app frontend.

## Prerequisites

1. Firebase project with Authentication enabled
2. Email/Password and Google Sign-In providers configured
3. Firebase web configuration values

## Setup Steps

### 1. Configure Firebase Options

Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase project configuration:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'your-actual-web-api-key',
  appId: 'your-actual-web-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  authDomain: 'your-project-id.firebaseapp.com',
  storageBucket: 'your-project-id.appspot.com',
);
```

### 2. Enable Authentication Providers

In the Firebase Console:
1. Go to Authentication > Sign-in method
2. Enable Email/Password provider
3. Enable Google Sign-In provider
4. Configure authorized domains for your app

### 3. Create Admin User

Create a Firebase user account for the admin:
- Email: `admin@potteryapp.test` (or your preferred admin email)
- Set a secure password
- This replaces the hardcoded admin credentials

### 4. Update Backend

The backend must be updated to verify Firebase ID tokens instead of the previous JWT implementation. See the main iteration document for backend changes.

## Features Implemented

### Email/Password Authentication
- Sign in with email and password
- Proper error handling with user-friendly messages
- Automatic token refresh

### Google OAuth
- One-tap Google Sign-In
- Seamless integration with Firebase Auth
- Profile information retrieval

### Session Management
- Automatic token refresh
- Persistent session storage
- Clean sign-out handling

### Security
- Firebase ID tokens for backend authentication
- Secure token storage using SharedPreferences
- Automatic session validation

## Error Handling

The app provides user-friendly error messages for common authentication failures:
- Invalid email format
- Wrong password
- Account not found
- Account disabled
- Network errors
- Too many failed attempts

## Testing

Run tests with:
```bash
flutter test
```

Key test files:
- `test/auth_state_test.dart` - Auth state management
- `test/firebase_auth_service_test.dart` - Firebase integration

## Development Notes

- Firebase options file is configured for all platforms (web, iOS, Android, macOS, Windows)
- The auth repository maintains the same interface while using Firebase underneath
- Google Sign-In is fully integrated with Firebase Auth
- All tokens are Firebase ID tokens suitable for backend verification
