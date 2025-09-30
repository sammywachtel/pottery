# Pottery App Development Plan — Organized by Iterations

> **Objective:** Migrate from hardcoded authentication to full user management system; implement user settings and profile features; deliver in **clean, testable iterations** with rigorous documentation; and **remove old code as we go**.

---

## 0) Executive Summary

**Current State:** The pottery catalog app has a solid foundation with Flutter frontend, FastAPI backend, Firestore for data, and GCS for photo storage. However, it currently uses a hardcoded `fake_users_db` with admin/admin credentials, making it unsuitable for production.

**Critical Production Blocker:** Cannot deploy with only hardcoded authentication - need real user registration and management.

**This Development Plan:**
1. **Migrate authentication** from `fake_users_db` to Firebase Authentication with email/password + Google OAuth
2. **Implement user registration** with proper validation and security
3. **Add user settings** including theme toggle and avatar upload
4. **Build profile management** with preferences and data persistence
5. Deliver in **small, verifiable iterations**, each with full tests, docs, and **code deletion** of superseded paths.

---

## 1) Current Findings

### ✅ **Strengths (Already Working)**
- **User Data Isolation**: All items already have `user_id` field for proper data separation
- **JWT Security**: Proper JWT token handling with bcrypt password hashing
- **Theme System**: Solid pottery-themed design system with Google Fonts integration
- **Photo Pipeline**: Robust photo upload/storage with signed URLs and GCS integration
- **State Management**: Riverpod setup for Flutter state management
- **Typography Issues**: Recently resolved text visibility and dark theme problems

### ❌ **Critical Issues (Production Blockers)**
- **Hardcoded Users**: `fake_users_db` with only admin/admin prevents real deployment
- **No Registration**: No way for new users to create accounts
- **No Profile Management**: Missing user settings, preferences, avatars
- **Manual Theme Only**: No user control over light/dark theme switching

---

## 2) Design Principles

- **Firebase-first authentication:** Leverage Google's battle-tested auth system for security and scalability
- **Incremental migration:** Replace fake auth piece by piece while maintaining functionality
- **User-centric design:** All features should enhance the pottery documentation workflow
- **Mobile-first UI:** Touch-friendly controls and responsive layouts
- **Data consistency:** Maintain existing user_id isolation patterns
- **Quality gates:** Each iteration must include tests, docs, and cleanup
- **Comprehensive documentation:** Every iteration must conclude with detailed notes in `.local_docs/ITERATION_NOTES.md` (see template .local_docs/ITERATION_NOTES_TEMPLATE.md)

---

## 3) Iteration Plan

> **Rule:** Each iteration produces: (1) green tests, (2) updated docs, (3) immediate removal of deprecated code.

### **Iteration 1 — Firebase Authentication Migration (CRITICAL)**

**Goal:** Replace `fake_users_db` with Firebase Authentication to enable real user accounts.

**Backend Changes:**
- Enable Firebase Auth in GCP project console
- Add Firebase Admin SDK to FastAPI backend
- Replace `fake_users_db` with Firebase token verification
- Update `get_current_user()` to verify Firebase JWT tokens
- Create user profile sync to Firestore for additional data
- **DELETE**: Remove `fake_users_db` completely

**Frontend Changes:**
- Add Firebase Auth dependencies to pubspec.yaml:
  - `firebase_auth: ^4.15.3`
  - `firebase_core: ^2.24.2`
  - `google_sign_in: ^6.1.5`
- Update auth repository for Firebase integration
- Modify login flow to use Firebase Authentication

**Testing:**
- Unit tests for Firebase token verification
- Integration tests for auth flow
- Migration test: existing admin user → Firebase user

**Acceptance Criteria:**
- ✅ Firebase Auth enabled and configured
- ✅ Backend verifies Firebase tokens instead of fake DB
- ✅ Admin user migrated to Firebase
- ✅ All existing functionality works with new auth
- ✅ `fake_users_db` code completely removed
- ✅ Documentation updated with new auth setup

**Iteration Documentation:**
- ✅ **Complete `.local_docs/ITERATION_NOTES.md`** with:
  - Files changed and nature of modifications
  - Overall iteration summary and lessons learned
  - Tests created and test results
  - Any technical debt acquired during iteration
  - Outstanding work that needs follow-up in future iterations
  - Performance impact and security considerations

### **Iteration 2 — Infrastructure & CI/CD Pipeline (Production Foundation)**

**Goal:** Establish production-grade infrastructure with proper environments, CI/CD pipeline, and deployment automation.

**Environment Setup:**
- **Dev Environment**:
  - GitHub branch: `develop`
  - Firebase project: `pottery-app-dev`
  - Firestore database: dev instance
  - GCS bucket: `pottery-photos-dev`
  - Cloud Run service: `pottery-backend-dev`
- **Test/Staging Environment**:
  - GitHub branch: `staging`
  - Firebase project: `pottery-app-staging`
  - Firestore database: staging instance
  - GCS bucket: `pottery-photos-staging`
  - Cloud Run service: `pottery-backend-staging`
- **Production Environment**:
  - GitHub branch: `main`
  - Firebase project: `pottery-app-prod`
  - Firestore database: production instance
  - GCS bucket: `pottery-photos-prod`
  - Cloud Run service: `pottery-backend-prod`

**CI/CD Pipeline (GitHub Actions):**
- **Pull Request Workflow**:
  - Automated testing (unit, integration, widget tests)
  - Code quality checks (linting, formatting)
  - Security scanning
  - Flutter build verification
- **Deployment Workflows**:
  - `develop` → auto-deploy to dev environment
  - `staging` → auto-deploy to staging environment
  - `main` → auto-deploy to production environment
- **Environment Promotion Process**:
  - Feature branches → `develop` → `staging` → `main`
  - Manual approval gates for staging → production
  - Automated rollback capabilities

**Infrastructure as Code:**
- Terraform configurations for GCP resources
- Environment-specific configuration management
- Secrets management via GitHub Secrets
- Database migration scripts
- Monitoring and alerting setup

**Branch Protection & Git Strategy:**
- Protected branches with required PR reviews
- Status checks must pass before merging
- No direct pushes to `staging` or `main`
- Semantic versioning and release tagging

**Configuration Management:**
- Environment-specific `.env` files
- Firebase project configurations
- API endpoint configurations
- Feature flags for environment-specific behavior

**Acceptance Criteria:**
- ✅ Three complete environments (dev/staging/prod) deployed and accessible
- ✅ GitHub Actions CI/CD pipeline functional for all environments
- ✅ Automated testing pipeline prevents broken deployments
- ✅ Environment promotion process documented and tested
- ✅ Infrastructure reproducible via Terraform
- ✅ Secrets and configurations properly managed
- ✅ Monitoring and alerting operational
- ✅ Rollback procedures tested and documented

**Iteration Documentation:**
- ✅ **Update `.local_docs/ITERATION_NOTES.md`** with:
  - Infrastructure components deployed and configurations
  - CI/CD pipeline setup and testing results
  - Environment-specific configurations and differences
  - Terraform scripts created and deployment verification
  - Security considerations and secrets management approach
  - Performance benchmarks and monitoring setup

### **Iteration 3 — User Registration System**

**Goal:** Enable new users to create accounts via email/password and Google OAuth.

**Backend Features:**
- User registration validation (email uniqueness)
- Firestore user profile creation
- User profile endpoints:
  - `GET /api/users/me` - Current user profile
  - `PUT /api/users/me` - Update profile
- Email verification integration (optional)

**Frontend Features:**
- Registration screen with email/password form
- Google Sign-In button integration
- Input validation and error handling
- Registration success/error flows

**Database Schema (Firestore):**
```
users/{userId}/
  - email: string
  - username: string (unique)
  - full_name: string
  - avatar_url: string (optional)
  - created_at: timestamp
  - email_verified: boolean
  - provider: "email" | "google"
  - preferences: {
      theme: "light" | "dark" | "system"
      notifications: boolean
    }
```

**Acceptance Criteria:**
- ✅ New users can register with email/password
- ✅ Google OAuth registration works
- ✅ User profiles stored in Firestore
- ✅ Email uniqueness validation
- ✅ Registration UI is intuitive and mobile-friendly

**Iteration Documentation:**
- ✅ **Update `.local_docs/ITERATION_NOTES.md`** with:
  - User registration flow implementation details
  - Firebase Auth integration and configuration changes
  - Firestore schema changes and data migration notes
  - UI/UX components created for registration screens
  - Security validation and error handling implemented
  - Testing results for email/password and Google OAuth flows

### **Iteration 4 — User Settings & Theme Control + UI/UX Improvements**

**Goal:** Add user settings panel with theme switching and improve pottery item detail UI organization.

**Frontend Features:**
- Dedicated settings page/screen
- Theme toggle: Light/Dark/System with state management
- Settings navigation from main app (gear icon)
- Theme persistence across app sessions
- Smooth theme transition animations
- Theme preview in settings

**UI/UX Improvements:**
- **Pottery Item Detail Screen Redesign:**
  - Grid-oriented layout for better information organization
  - Replace measurements list with structured grid/card layout
  - Visual hierarchy improvements for better readability
- **Timezone & Date/Time Display:**
  - Remove timezone pill (currently showing "Timezone: UTC")
  - Display all dates/times in user's local timezone
  - Include local timezone abbreviation in time display (e.g., "6:49 PM EST")
  - Update both creation timestamps and photo upload times

**Backend Integration:**
- User preferences storage in Firestore
- Settings sync across devices

**Architecture:**
- Settings feature folder structure
- Theme provider/controller for manual switching
- SharedPreferences for local caching
- Riverpod state management integration
- Date/time formatting utilities for local timezone display

**Acceptance Criteria:**
- ✅ Settings page accessible from main navigation
- ✅ Theme toggle works (Light/Dark/System)
- ✅ Theme preference persists across sessions
- ✅ Smooth animations during theme transitions
- ✅ Settings sync to Firestore user preferences
- ✅ Item detail page uses improved grid layout
- ✅ Measurements displayed in organized card/grid format
- ✅ All timestamps show local time with timezone (e.g., "6:49 PM EST")
- ✅ Timezone pill completely removed from UI

**Iteration Documentation:**
- ✅ **Update `.local_docs/ITERATION_NOTES.md`** with:
  - UI/UX redesign details and design decisions
  - Theme system architecture and state management changes
  - Date/time formatting utilities and timezone handling
  - Settings persistence implementation and Firestore integration
  - Performance impact of UI changes and animation optimizations
  - User experience testing results and accessibility improvements

### **Iteration 5 — Avatar Upload & Profile Management**

**Goal:** Complete user profile features with avatar upload and management.

**Backend Features:**
- Avatar storage API following existing photo patterns
- Signed URL generation for avatar images
- `POST /api/users/me/avatar` endpoint
- Avatar crop/resize functionality

**Frontend Features:**
- Avatar upload with image picker integration
- Camera/gallery options on mobile
- Avatar crop/resize UI
- Avatar display in app header/profile area
- Profile editing form

**Quality & Testing:**
- Unit tests for avatar upload
- Widget tests for settings UI components
- Integration tests for profile management

**Acceptance Criteria:**
- ✅ Users can upload and crop profile avatars
- ✅ Avatars display consistently across the app
- ✅ Avatar storage follows GCS patterns
- ✅ Mobile camera/gallery integration works
- ✅ Profile editing saves to Firestore

**Iteration Documentation:**
- ✅ **Update `.local_docs/ITERATION_NOTES.md`** with:
  - Avatar upload pipeline implementation and GCS integration
  - Image processing and cropping functionality details
  - Mobile camera/gallery integration and permissions handling
  - Profile management API endpoints and data validation
  - Storage optimization and signed URL generation for avatars
  - Cross-platform compatibility testing results

### **Iteration 6 — Data Model Enhancements**

**Goal:** Enhance pottery item tracking with weight measurements and update timestamps.

**Backend Features:**
- Add weight field to measurement details (greenware, bisque, final)
- Add `updated_at` timestamp field to pottery items
- Automatically update `updated_at` on:
  - Item edits (name, clay type, location, glaze, notes, etc.)
  - Measurement changes
  - Photo operations (add, update, delete)
- Update API endpoints to return `updated_at` field
- Database migration to add fields to existing items

**Frontend Features:**
- Update measurement input forms to include weight
- Display weight in measurements grid (e.g., "Weight: 2.5 lbs")
- Show "Last updated" timestamp on item detail page
- Update measurement display cards to show weight field
- Update photo upload/delete handlers to trigger update timestamp

**Database Schema Changes (Firestore):**
```
items/{itemId}/
  measurements:
    greenware:
      height: double
      width: double
      depth: double
      weight: double  # NEW
    bisque:
      height: double
      width: double
      depth: double
      weight: double  # NEW
    final:
      height: double
      width: double
      depth: double
      weight: double  # NEW
  updated_at: timestamp  # NEW - tracks last modification
```

**Acceptance Criteria:**
- ✅ Weight field added to all three measurement stages
- ✅ Weight input available in item form and detail page
- ✅ Weight displayed in measurements grid with proper units (lbs or kg)
- ✅ `updated_at` timestamp tracks all item changes
- ✅ `updated_at` updates when photos are added/deleted
- ✅ Last updated time displayed on item detail page
- ✅ Migration script updates existing items with default values
- ✅ Tests verify weight field and timestamp updates

**Iteration Documentation:**
- ✅ **Update `.local_docs/ITERATION_NOTES.md`** with:
  - Database schema changes and migration details
  - Weight field implementation and unit handling
  - Timestamp tracking logic and trigger points
  - API endpoint changes and response format updates
  - Frontend component updates for weight display
  - Data migration results and validation

### **Iteration 7 — Polish & Advanced Features**

**Goal:** Add advanced user experience features and final polish.

**Features:**
- Email verification system
- Password reset functionality
- Multiple theme variants (beyond light/dark)
- Font size accessibility options
- Settings export/import
- Settings backup to cloud

**Mobile Experience:**
- Responsive layouts for different screen sizes
- Touch-friendly controls
- Accessibility improvements

**Documentation:**
- API documentation for user profile endpoints
- Theme customization guide
- User onboarding documentation

**Acceptance Criteria:**
- ✅ Email verification flow works
- ✅ Password reset via Firebase Auth
- ✅ Advanced theme options available
- ✅ Accessibility features implemented
- ✅ Complete documentation published

**Final Iteration Documentation:**
- ✅ **Complete `.local_docs/ITERATION_NOTES.md`** with:
  - Advanced features implementation and configuration
  - Email verification and password reset integration details
  - Accessibility compliance and testing results
  - Performance optimization results and metrics
  - Final production readiness checklist and deployment notes
  - Post-launch monitoring and maintenance recommendations

---

## 4) Testing Strategy

### Unit Tests
- Firebase token verification logic
- User profile data models
- Theme switching controllers
- Settings persistence mechanisms

### Integration Tests
- Complete auth flow (registration → login → profile)
- Theme switching across app sessions
- Avatar upload pipeline
- Settings sync between devices

### Widget Tests
- Registration/login forms
- Settings UI components
- Theme toggle controls
- Avatar upload interface

### Quality Gates
- All tests must pass before iteration completion
- Test coverage maintained above 80%
- No broken functionality in existing features
- Performance benchmarks for auth operations

---

## 5) Migration & Cleanup Plan

### **Immediate Deletions (Iteration 1)**
- `fake_users_db` and related hardcoded auth logic
- Development-only user validation code
- Placeholder authentication comments

### **Code to Modernize**
- Existing JWT handling → Firebase JWT verification
- Manual theme switching → User preference-based
- Static user context → Dynamic user profiles

### **Documentation Updates**
- README authentication setup instructions
- API documentation for new endpoints
- Development setup with Firebase configuration
- Deployment guide with Firebase Auth

---

## 6) Risk Mitigation

### **Critical Dependencies**
- Firebase Authentication service availability
- GCP project configuration and permissions
- Flutter web compatibility with Firebase Auth

### **Rollback Strategy**
- Keep Firebase and legacy auth running in parallel during Iteration 1
- Feature flags for new authentication system
- Backup of existing admin user in Firebase before migration

### **Performance Considerations**
- Firebase Auth SDK bundle size impact
- Token verification latency
- Firestore read/write costs for user preferences

---

## 7) Current Development Status

### **✅ Completed (Prior Work)**
- Typography System: Fixed dark theme and Google Fonts integration
- Text Visibility: Resolved pottery theme extension issues
- Project Structure: Backend/frontend organization complete
- Photo Pipeline: Robust image upload and storage working

### **🚀 Next Actions (Start Iteration 1)**
1. Enable Firebase Authentication in GCP console
2. Add Firebase dependencies to backend and frontend
3. Implement Firebase token verification in FastAPI
4. Update Flutter auth repository for Firebase
5. Test migration with existing admin user
6. Remove `fake_users_db` completely

### **📋 Iteration Tracking**
- **Current Iteration**: Ready to start Iteration 1
- **Timeline**: Each iteration estimated at 1-2 weeks (6 iterations total)
- **Success Metrics**: Production-ready authentication, CI/CD infrastructure, user registration, settings management

---

## Notes

- **Firebase vs Alternatives**: Firebase chosen for seamless Flutter integration and production-grade security
- **Existing Patterns**: Avatar upload will follow established photo storage patterns in the app
- **Theme Foundation**: Current pottery design system provides excellent foundation for user customization
- **Mobile-First**: All new UI features designed for touch interaction and responsive layouts

This iterative approach ensures each piece can be tested, documented, and deployed independently while maintaining system stability throughout the migration.
