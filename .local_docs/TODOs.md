# Pottery App TODO List

## 🔥 In Progress

*(No tasks currently in progress)*

## ✅ Recently Completed

### Current Session (feature/primary-photo-selection branch)

- ✅ **Primary photo selection with star indicators** - Full UI implementation
  - Added `isPrimary` boolean field to Photo model (backend + frontend)
  - Added PATCH endpoint `/api/items/{item_id}/photos/{photo_id}/primary`
  - Added "Set as primary" option in photo card three-dots menu
  - Added star button in fullscreen photo viewer
  - Added star badges on photo carousel (horizontal scroll list on detail view)
  - List view displays primary photo, or most recent photo if none selected
  - Backend auto-sets first uploaded photo as primary if none selected

- ✅ **Fixed photo flickering during scroll**
  - Added `cacheExtent: 1000.0` to CustomScrollView (keeps ~3 screens cached)
  - Converted `_PotteryItemCard` to StatefulWidget with `AutomaticKeepAliveClientMixin`
  - Reduced CachedNetworkImage fade durations (300ms→150ms, 100ms→50ms)
  - Added memory cache limits (400x400 for cards, 100x100 for thumbnails)
  - Photos no longer flicker or reload during scrolling

- ✅ **Interactive deployment script** (local/Docker track complete)
  - Location: `scripts/deploy.sh`
  - Interactive menu: 1) Backend Only, 2) Frontend Only, 3) Both
  - Auto-detects USB devices via adb with authorization handling
  - Auto-detects local IP for Docker backend connection
  - Always builds AAB for Play Store alongside device installation
  - Comprehensive post-deployment instructions
  - Skips infrastructure setup to avoid gcloud auth issues
  - Backend deploys first in "Both" mode to ensure fresh backend

- ✅ **"SL" suffix for sideloaded apps**
  - Local builds: "Pottery Studio Local SL"
  - Dev builds: "Pottery Studio Dev SL"
  - Prod builds: "Pottery Studio" (no SL suffix)
  - Created flavor-specific `strings.xml` for local and dev

- ✅ **Version checking to prevent backend/frontend mismatches**
  - Backend `/api/version` endpoint returns backend version and min frontend version
  - Frontend VersionCheckService compares semantic versions on startup
  - VersionGuard widget shows non-dismissible update dialog when outdated
  - "Update Now" button opens Play Store (or browser fallback)
  - Prevents errors from incompatible versions

- ✅ **Responsive card layouts with adaptive aspect ratios**
  - Removed fixed 3:4 aspect ratio from photo display
  - Cards now adapt to each photo's natural aspect ratio
  - Portrait photos display taller, landscape photos display wider
  - Masonry grid creates dynamic, Pinterest-style layout
  - Placeholder/error states still use 3:4 ratio to prevent collapse

- ✅ **Single-column mobile layout for landscape photos**
  - Mobile (< 600px): 1 column - landscape photos take full width
  - Tablet (600-900px): 2 columns
  - Desktop (> 900px): 3 columns
  - Fixes landscape photo cropping on mobile devices

- ✅ **Fixed AppBar overflow**
  - Wrapped "Pottery Studio" title in Flexible widget with ellipsis
  - Reduced icon size (28→24) and spacing (8→6)
  - Title can now shrink gracefully on narrow screens

- ✅ **Fixed dropdown crash when editing photos**
  - Added check to ensure photo.stage exists in dropdown options
  - Falls back to first option if stage not found
  - Prevents Flutter assertion error: "Either zero or 2 or more DropdownMenuItems"

### Previous Sessions

- ✅ Create account deletion request webpage/form for Google Play compliance
- ✅ Implement backend endpoint for account deletion requests
- ✅ Complete Google Play Data Safety form in Play Console
- ✅ Fix photo deletion and re-upload issue (photos not sticking after delete)
- ✅ Add Cone field to item form (optional text field)
- ✅ Make only Name field required on item form (Location, Clay Type optional)
- ✅ Convert Clay Type from dropdown to free-form text entry
- ✅ Move Creation date & time selector to bottom of form
- ✅ Consolidate scripts: Move `backend/scripts/` → `scripts/backend/`, remove duplicate `scripts/frontend/`
- ✅ Update all documentation to fix dead script references

## 📋 Pending Tasks

### Firebase & Authentication

1. Run setup-firebase-complete.sh to create iOS apps automatically
2. Test Google Sign-In functionality on macOS (currently working on Chrome, needs testing on Safari)

### Pottery App Features - High Priority

3. **Display last updated date on item list screen** - Show last updated date instead of created date
   - Show the most recent date between item update and photo upload
   - Consider showing both created and updated dates (e.g., "Updated 2d ago")
   - Reference: `frontend/lib/src/features/items/views/items_home_page.dart` (_PotteryItemCard)

4. **Quick stage advancement** - Add quick method to change item stage on detail view screen
   - Add stage selector/stepper at top of item detail view (near current status badge)
   - Allow quick stage advancement: Greenware → Bisque → Final
   - Show confirmation dialog before changing stage
   - Consider adding timestamps for each stage transition
   - Reference: `frontend/lib/src/features/items/views/item_detail_page.dart`

5. **Default stage to Greenware on create/edit screen** - Pre-select Greenware as default stage
   - Set "Greenware" as default value in item form dropdown/selector
   - Saves user from having to remember to select it every time
   - Most pottery starts at greenware stage
   - Reference: `frontend/lib/src/features/items/views/item_form_page.dart`

6. **Warn about unsaved changes** - Prevent accidental data loss when leaving edit screens
   - Detect if form has unsaved changes (use Form dirty state tracking)
   - Show dialog when user tries to navigate back or close screen
   - Dialog options: "Save and close" / "Discard changes" / "Cancel"
   - Apply to both item form and photo edit dialogs
   - Reference: `frontend/lib/src/features/items/views/item_form_page.dart`, `item_detail_page.dart`

7. **Display cone value on item detail view screen** (under glaze value) - Field exists in form, needs to show on detail view

8. **Add modified/updated datetime tracking** - Track when items are edited or photos are added/deleted

9. Add filtering functionality to pottery item list

10. Implement search bar for pottery items (search all fields including descriptions)

11. Add filter options: clay type, location, created/updated date ranges, glaze, status

12. Add description/caption field to photos

13. Add weight field to measurement details for each pottery stage (greenware, bisque, final)

### Measurement Features

14. Develop camera-based dimension measurement feature for pottery pieces
15. Implement photo analysis for measuring pottery dimensions with reference object
16. Add measurement clarification notes (maximum height, width, depth vs base dimensions)
17. Update measurement UI screens with maximum dimension guidance

### Privacy & Compliance

18. Create privacy policy document for pottery app
19. Implement in-app consent dialogs for data collection
20. Add proper permission request flows for camera and storage access
21. Add transparent data handling disclosures in app UI
22. Implement proper age verification for child privacy protection (if applicable)
23. Add Delete Account button in app settings (link to deletion form)

### Code Quality & Infrastructure

24. Add comprehensive integration tests for photo upload/delete flow
25. Add unit tests for new Cone field validation
26. Consider adding photo compression before upload to reduce storage costs
27. Implement caching strategy for item list to improve performance

### DevOps & Deployment

28. **Expand interactive deployment script to dev/prod environments** - Add cloud deployment support
    - ✅ Local/Docker track complete (see Recently Completed section)
    - **Dev environment support** - Deploy to Google Cloud Run (dev)
      - Build and deploy backend to Cloud Run dev
      - Build frontend with dev backend URL
      - gcloud authentication check before deployment
    - **Prod environment support** - Deploy to Google Cloud Run (prod)
      - Build and deploy backend to Cloud Run prod
      - Build frontend with prod backend URL
      - IAM role verification
      - Production safety checks and confirmations
    - **Authentication verification**: For cloud deployments (dev/prod backend)
      - Check if user is logged in with `gcloud auth list`
      - Verify account has required IAM roles (documented in `backend/docs/how-to/setup-production.md`)
      - Prompt user to login with correct account if needed
      - List required roles: Cloud Run Admin, Artifact Registry Writer, etc.
    - **Reference**: Existing scripts in `scripts/backend/deploy-dev.sh`, `deploy-prod.sh`
    - **Location**: `scripts/deploy.sh` (already exists for local/Docker)

---

## Summary

- **0** tasks in progress
- **20** tasks recently completed (9 from current session)
- **28** tasks pending
  - 2 Firebase/Auth
  - 11 High priority app features
  - 4 Measurement features
  - 6 Privacy/compliance
  - 4 Infrastructure/quality
  - 1 DevOps/deployment (dev/prod expansion)

## Notes

### Current Session Highlights
- **Version:** Frontend v1.2.5+8, Backend v0.2.0 (min_frontend_version: 1.2.3)
- **Branch:** feature/primary-photo-selection
- Photo display completely overhauled: adaptive aspect ratios, single-column mobile layout
- Deployment workflow streamlined: interactive script with USB detection and AAB building
- Version checking prevents backend/frontend compatibility issues
- All photo-related UX issues resolved: flickering, cropping, star indicators

### General Notes
- Primary photo selection complete: Users can set primary photo via three-dots menu, fullscreen viewer, or photo carousel
- Form fields have been updated: Name (required), Clay Type (optional text), Location (optional), Cone (optional text)
- Scripts consolidated: Infrastructure scripts in `scripts/backend/`, frontend build scripts in `frontend/scripts/`
- Photo deletion bug fixed: Photos now properly persist after delete and re-upload
- Deployment script location: `scripts/deploy.sh` (local/Docker complete, dev/prod pending)
