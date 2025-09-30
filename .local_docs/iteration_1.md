# Iteration 1 — Firebase Authentication Migration

## Objectives
- Replace `fake_users_db` and custom password checks with Firebase Authentication verification.
- Keep existing admin capabilities by migrating the seed user into Firebase.
- Maintain current API surface while delegating identity proof to Firebase JWT tokens.
- Document the new auth setup so local devs and CI can bootstrap credentials quickly.

## Prerequisites & Environment
- Ensure the GCP project used for Firestore/GCS has Firebase enabled.
- In Firebase console enable Email/Password and Google Sign-In providers.
- Generate a Web API key and download the service account JSON with the `firebase-adminsdk` role; store path in `FIREBASE_CREDENTIALS_FILE` (backend) and values in Flutter `firebase_options.dart`.
- Add `.env` entries: `FIREBASE_PROJECT_ID`, `FIREBASE_CREDENTIALS_FILE`, `FIREBASE_API_KEY`, `FIREBASE_AUTH_DOMAIN`.
- Create a Firebase user for the existing admin (email `admin@potteryapp.test` or similar) and set a secure password.

## Backend Implementation (FastAPI)
1. **Dependencies**
   - Add `firebase-admin>=6.4.0` to `backend/requirements.txt` (or poetry config) and run `pip install -r requirements.txt`.
2. **Firebase Admin bootstrap**
   - Create `app/core/firebase.py` that initializes `firebase_admin` using the service account file once per process.
   - Expose helpers for verifying ID tokens and resolving user information.
3. **Auth utilities**
   - Update `app/dependencies.py` (or wherever `get_current_user` lives):
     - Accept the Bearer token, call `firebase_admin.auth.verify_id_token`.
     - Map the decoded token to the internal `User` schema (uid, email, name, picture).
     - On verification failures raise `HTTPException(status_code=401)`.
4. **User profile sync**
   - When a Firebase user is first seen, create/update a Firestore doc at `users/{uid}` with email, display name, and timestamps.
   - Add a repository/service layer to encapsulate Firestore writes (e.g., `app/services/user_profile.py`).
5. **API adjustments**
   - Ensure existing endpoints relying on `current_user` only use the Firebase-backed `User` model.
   - Remove references to `fake_users_db`, including data structures, startup seeds, and utility functions.
6. **Configuration & settings**
   - Update `settings.py` to surface the Firebase config values and validate on startup.
   - Ensure unit tests can inject mock Firebase tokens (provide a `verify_token` interface that can be patched).

## Frontend Implementation (Flutter)
1. **Dependencies**
   - Add to `frontend/pubspec.yaml`: `firebase_core`, `firebase_auth`, `google_sign_in` (versions from DEVELOPMENT_TODO.md) and run `flutter pub get`.
2. **Firebase initialization**
   - Run `flutterfire configure` to generate `lib/firebase_options.dart` tailored to each platform.
   - Update `main.dart` to call `WidgetsFlutterBinding.ensureInitialized();` followed by `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);` before running the app.
3. **Auth repository refactor**
   - Replace hardcoded credential checks with `FirebaseAuth.instance.signInWithEmailAndPassword`.
   - Add Google OAuth via `GoogleSignIn().signIn()` and `GoogleAuthProvider`. Ensure tokens refresh automatically.
   - Update Riverpod providers to expose auth state streams from `FirebaseAuth.authStateChanges()`.
4. **Session handling**
   - On successful login obtain the ID token via `user.getIdToken()` and supply it in backend HTTP headers (`Authorization: Bearer <token>`).
   - Update API client to refresh the token before expiry (use `getIdToken(true)` when needed).
5. **UI updates**
   - Replace the current login form logic with async Firebase calls, surface friendly error messages (invalid credentials, disabled user, etc.).
   - Add loading states while Firebase resolves sign-in.
6. **Admin migration validation**
   - Confirm the migrated admin can sign in through the updated UI and still see their existing pottery data (FireStore `user_id` alignment).

## Testing Strategy
- **Unit tests (backend):** Patch Firebase verification to simulate valid/invalid tokens; assert `get_current_user` returns proper models and rejects tampered tokens.
- **Integration tests (backend):** Use Firebase emulator or mocked token responses to hit protected endpoints and confirm 401s for missing tokens.
- **Flutter tests:**
  - Add widget tests for the login screen to ensure error messaging and loading states display correctly (use Firebase Auth mocks).
  - Add repository tests to check token retrieval and header injection logic.
- **Manual verification:**
  - Run the app against Firebase emulator or staging project, log in via email/password and Google.
  - Confirm existing pottery items remain accessible and `create/update` flows use the Firebase UID.

## Documentation & Iteration Notes
- Maintain `.local_docs/ITERATION_NOTES.md` during the iteration so it is ready for review on completion.
- Ensure the entry covers files changed and their purpose, overall iteration summary/lessons learned, tests created or executed with results, newly discovered technical debt, outstanding follow-up items, and performance or security considerations.
- Log new technical debt or follow-up items and clearly flag owners/timelines.
- Highlight outstanding work that rolls into Iteration 2 (infrastructure) to keep momentum aligned with the master plan.

## Cleanup & Rollout
- Delete `fake_users_db` definitions and any references in both backend and frontend.
- Remove obsolete tests that depended on hardcoded credentials; replace with Firebase-oriented cases.
- Update `.env.example`, README, and API docs with new Firebase setup steps.
- Double-check no Firebase secrets are committed (ensure `.gitignore` covers service account JSON).
- After merging, monitor Firebase Auth dashboard and backend logs for unexpected errors.

## Definition of Done Checklist
- [ ] Firebase project configured with required providers and service account.
- [ ] Backend verifies Firebase ID tokens and persists user profiles to Firestore.
- [ ] Frontend login flow uses Firebase Auth for email/password and Google sign-in.
- [ ] Admin user migrated and confirmed able to log in to existing data.
- [ ] Automated tests updated/passing; manual smoke test completed.
- [ ] Legacy auth code removed; docs updated for new setup.
- [ ] `.local_docs/ITERATION_NOTES.md` updated with required iteration summary details.
