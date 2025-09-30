# Iteration 1 Remediation & Acceptance Criteria

## 1. Remove Legacy Authentication Path
- **Problem:** `backend/auth.py:268`, `backend/main.py:187`, and `backend/tests/test_auth.py:6` still rely on `fake_users_db` and JWT tokens.
- **Remediation Tasks:**
  - Delete `fake_users_db`, legacy password helpers, and the legacy `/api/token` endpoint.
  - Update dependency injection so every protected endpoint asserts a Firebase ID token.
  - Replace legacy auth fixtures/tests with Firebase-token based flows or mocks.
  - Retire helper scripts that expect admin/admin credentials.
- **Acceptance Criteria:**
  - No references to `fake_users_db`, `create_access_token`, or legacy JWT helpers in the codebase.
  - `/api/token` removed or replaced with Firebase-aware flow.
  - `cd backend && pytest` passes with Firebase-token mocks (no admin/admin logins).
  - Manual request with a valid Firebase ID token succeeds; request without token returns 401.

## 2. Fix Firebase Enablement Logic
- **Problem:** `Settings.firebase_enabled` requires `FIREBASE_API_KEY` and `FIREBASE_AUTH_DOMAIN`, causing production servers to fallback to legacy auth.
- **Remediation Tasks:**
  - Treat Firebase as enabled when `FIREBASE_PROJECT_ID` is present and either a service-account file or ADC credentials exist.
  - Update settings validation and add unit tests.
  - Document backend-specific environment expectations.
- **Acceptance Criteria:**
  - `settings.firebase_enabled` returns `True` with `FIREBASE_PROJECT_ID` plus credentials even if API key/auth domain are absent.
  - Unit tests cover enabled/disabled scenarios (`pytest tests/test_config.py` or equivalent) and all pass.
  - Backend startup logs show Firebase initializing in the default configuration.

## 3. Make User Profile Service Testable
- **Problem:** `UserProfileService` cannot be dependency-injected; tests fail (`pytest tests/test_user_profile_service.py`).
- **Remediation Tasks:**
  - Allow constructor injection of a Firestore client or provide an overridable getter for `_ensure_firestore_client`.
  - Update tests to supply async mocks and remove direct access to private globals.
- **Acceptance Criteria:**
  - `cd backend && pytest tests/test_user_profile_service.py` passes without patching private globals.
  - Production code still uses lazy Firestore initialization when no client is injected.

## 4. Align Iteration Documentation with Reality
- **Problem:** `.local_docs/ITERATION_NOTES.md` marks Iteration 1 as complete despite outstanding work and failing tests.
- **Remediation Tasks:**
  - Update the iteration entry to reflect in-progress status, document remaining tasks, and remove inaccurate “✅ COMPLETE” markers.
  - Ensure Definition of Done checkboxes match the codebase state.
- **Acceptance Criteria:**
  - `.local_docs/ITERATION_NOTES.md` accurately lists completed work, outstanding items, and current test status.
  - DoD checklist is only marked complete once tasks 1-3 are done and verified.

## 5. Exercise the Real Auth Repository in Flutter Tests
- **Problem:** `frontend/test/repositories/firebase_auth_repository_test.dart` tests a stub instead of `AuthRepository`.
- **Remediation Tasks:**
  - Write tests that instantiate `AuthRepository` with mocked `ApiClient`, `LocalAuthStorage`, and `FirebaseAuthService`.
  - Validate login, Google sign-in, token refresh, and logout behavior using the production repository.
- **Acceptance Criteria:**
  - `frontend/test/repositories/firebase_auth_repository_test.dart` imports `src/data/repositories/auth_repository.dart`.
  - `cd frontend && flutter test test/repositories/firebase_auth_repository_test.dart` passes and covers Firebase token handling.

## Verification Checklist
1. Backend: `cd backend && pytest` (all suites green).
2. Flutter: `cd frontend && flutter test` (auth-related suites green).
3. Documentation: `.local_docs/ITERATION_NOTES.md` updated; Definition of Done in `iteration_1a.md` can be checked off with evidence.

## Additional Review Findings
- **Auth error-handling tests depend on Firestore** (`backend/tests/test_auth.py:162`, `backend/services/firestore_service.py:39`): Acceptance requires stubbing Firestore in the auth suite so malformed-token requests return 401 instead of 503. Verify with `cd backend && pytest tests/test_auth.py`.
- **Settings tests lack required env vars** (`backend/tests/test_config.py:17`): Seed minimal `GCP_PROJECT_ID` / `GCS_BUCKET_NAME` inside each test (or fixtures) so `Settings()` can instantiate. Acceptance: all `tests/test_config.py` cases pass without ValidationError.
- **Firebase helpers need proper mocking** (`backend/core/firebase.py:36`, `backend/tests/test_firebase_core.py:44`): Patch `firebase_admin.initialize_app` and related calls in the core tests; ensure expired/revoked token paths don’t hit real Firebase. Acceptance: `cd backend && pytest tests/test_firebase_core.py` passes.
- **Migration tests assume real Firebase** (`backend/tests/test_migration_verification.py:205`): Inject Firebase mocks (create/get user) so migration flows complete without network calls. Acceptance: migration tests in that module pass using mocks only.
- **Repository tests still use a stub** (`frontend/test/repositories/firebase_auth_repository_test.dart:24`): Replace the test-local class with imports from `src/data/repositories/auth_repository.dart`, mocking dependencies. Acceptance: `cd frontend && flutter test test/repositories/firebase_auth_repository_test.dart` exercises `AuthRepository` directly.
- **Iteration notes must reflect current state** (`.local_docs/ITERATION_NOTES.md:9`): Keep status at "IN PROGRESS" until the above acceptance criteria and verification checklist succeed; update outcomes section once tests are green.
