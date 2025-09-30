# Iteration 1 — Firebase Authentication Migration

## Review Findings & Remediation
- **Remove legacy auth path** (`backend/auth.py:268`, `backend/main.py:187`, `backend/tests/test_auth.py:6`): Delete `fake_users_db`, legacy password helpers, and the `/api/token` JWT issuance. Update FastAPI dependencies so every protected route requires a Firebase ID token and adjust tests to post real tokens (or Firebase-mocked ones) instead of admin/admin credentials. Retire scripts that assume JWT login.
- **Fix Firebase feature flag** (`backend/config.py:27`): Treat Firebase as enabled when `FIREBASE_PROJECT_ID` is set and credentials are available (service account file or ADC). Remove the requirement for `FIREBASE_API_KEY`/`FIREBASE_AUTH_DOMAIN` on the backend so production cannot silently fall back to legacy auth. Add unit coverage around `settings.firebase_enabled`.
- **Make user profile service testable** (`backend/services/user_profile_service.py:12`, `backend/tests/test_user_profile_service.py:26`): Allow dependency injection for the Firestore client (e.g., accept it in the constructor or expose an overridable getter). Update the tests to provide an async mock and ensure `pytest` suite passes with `cd backend && pytest tests/test_user_profile_service.py`.
- **Align iteration documentation with reality** (`.local_docs/ITERATION_NOTES.md:9`, `.local_docs/ITERATION_NOTES.md:108`, `.local_docs/ITERATION_NOTES.md:115`): Revise the iteration record to reflect that the migration is in progress, document the failing tests, and move the remaining work into the follow-up section. Re-run the DoD checklist once the above fixes land.
- **Test the real auth repository** (`frontend/lib/src/data/repositories/auth_repository.dart:1`, `frontend/test/repositories/firebase_auth_repository_test.dart:1`): Replace the test-only stub with coverage that instantiates the actual `AuthRepository`, injecting mocked `ApiClient`, `LocalAuthStorage`, and `FirebaseAuthService`. Ensure `flutter test test/repositories/firebase_auth_repository_test.dart` exercises the production code and validates Firebase token handling.

### Verification
- Backend: `cd backend && pytest` (focus on auth and user profile suites after refactors).
- Flutter: `cd frontend && flutter test test/repositories/firebase_auth_repository_test.dart` plus targeted auth/widget suites.
- Documentation: Confirm `.local_docs/ITERATION_NOTES.md` reflects updated status and that the Definition of Done checklist in this file can be checked off with evidence.
