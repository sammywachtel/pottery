# Iteration 1C — Finalizing Firebase Auth Migration

## Objectives
- Clear the remaining blockers from Iteration 1B so the auth migration is production-ready.
- Stabilize backend/frontend test suites by introducing proper mocks and environment scaffolding.
- Ensure documentation and checklists accurately reflect system state before moving to Iteration 2.

## Planned Remediation Steps

### 1. Stub Firestore in Authentication Tests
- **Why:** `backend/tests/test_auth.py` currently exercises the real Firestore client, causing malformed token tests to return 503 instead of 401. This masks auth issues behind infrastructure noise.
- **How:** Inject a mock Firestore client (or patch `_ensure_firestore_client`) during the auth test fixture so protected endpoints don’t hit Firestore. Validate malformed tokens return 401 and success paths still work with mocked data.
- **Acceptance Criteria:**
  - `cd backend && pytest tests/test_auth.py` passes without depending on real Firestore.
  - Log output confirms no attempts to initialize Firestore during the auth suite.

### 2. Stabilize Settings/Firebase Enablement Tests
- **Why:** `Settings()` is instantiated at import time, so config tests fail unless required env vars are preloaded. This blocks automated validation of the new Firebase feature flag logic.
- **How:** Add a pytest fixture (or module-level bootstrap) that seeds `GCP_PROJECT_ID` / `GCS_BUCKET_NAME` before importing `config`. Refactor tests to use `importlib.reload` if needed to apply `patch.dict`. Ensure the tests cover service-account, ADC, and cloud environment paths.
- **Acceptance Criteria:**
  - `cd backend && pytest tests/test_config.py` passes with fresh environments.
  - Tests explicitly assert both enabled and disabled scenarios without validation errors.

### 3. Mock Firebase Admin in Core & Migration Suites
- **Why:** Several tests in `tests/test_firebase_core.py` and `tests/test_migration_verification.py` rely on live Firebase Admin SDK and fail when credentials are absent.
- **How:** Use `patch` to fake `firebase_admin.initialize_app`, `auth.verify_id_token`, `auth.create_user`, and `auth.get_user_by_email`. Provide deterministic responses for success/failure paths so tests validate our code instead of the SDK.
- **Acceptance Criteria:**
  - `cd backend && pytest tests/test_firebase_core.py tests/test_migration_verification.py` completes successfully offline.
  - Mock assertions confirm expected Firebase calls are made.

### 4. Update Flutter Repository Tests to Exercise Production Code
- **Why:** The current test defines a local stub; it never touches `src/data/repositories/auth_repository.dart`, leaving the real login logic unverified.
- **How:** Import `AuthRepository`, mock `ApiClient`, `LocalAuthStorage`, and `FirebaseAuthService`, and cover sign-in, Google sign-in, token refresh, and logout flows.
- **Acceptance Criteria:**
  - `frontend/test/repositories/firebase_auth_repository_test.dart` imports the real repository.
  - `cd frontend && flutter test test/repositories/firebase_auth_repository_test.dart` passes and covers token handling paths.

### 5. Sync Documentation with Reality
- **Why:** `.local_docs/ITERATION_NOTES.md` currently states Iteration 1 is complete while test suites still fail, potentially misleading stakeholders.
- **How:** Keep status as “IN PROGRESS” until Steps 1-4 are done, then summarize remediation outcomes and update the Definition of Done checklist in `iteration_1a.md` with evidence.
- **Acceptance Criteria:**
  - Iteration notes show accurate status and reference passing commands before marking complete.
  - Definition of Done boxes checked only after Steps 1-4 verification commands succeed.

## Verification Checklist
1. Backend: `cd backend && pytest` (all suites green).
2. Flutter: `cd frontend && flutter test` (repository + auth suites green).
3. Documentation: `.local_docs/ITERATION_NOTES.md` and `iteration_1a.md` updated post-verification.
