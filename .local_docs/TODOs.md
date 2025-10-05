# Pottery App TODO List

## 🔥 In Progress

*(No tasks currently in progress - ready for next feature!)*

## ✅ Recently Completed

### Current Session

- ✅ **Archive and Broken item management** - Complete visibility system with mutual exclusivity
  - Added `isArchived` and `isBroken` boolean fields to PotteryItem model (backend + frontend)
  - Implemented PATCH endpoint for partial item updates (no more validation errors)
  - Added "Archive Item" menu option in item detail view with confirmation dialog
  - Added "Broken" checkbox in item detail view (for all stages, not just Final)
  - Made broken and archived mutually exclusive at item level (auto-clears when setting the other)
  - Added visual badges: amber 'A' for archived, red 'B' for broken items
  - Added "Show only archived items" and "Show only broken items" filters
  - Filters are mutually exclusive (enabling one disables the other)
  - Default view hides both archived and broken items
  - Fixed timestamp display: now shows lastUpdatedDateTime instead of createdDateTime
  - Sorting by date now uses updatedDateTime (falls back to createdDateTime)
  - Reference: `items_home_page.dart:365-378`, `item_detail_page.dart`, `backend/routers/items.py`

- ✅ **Enhanced filter UI with clear AND/OR logic** - Reorganized filter dialog for clarity
  - Added section headers: VISIBILITY, FIRING STAGE, LOCATION
  - Added explanatory text under each section explaining filter behavior
  - Changed toggle labels from "Show" to "Include/Show only" for clarity
  - Added subtitles explaining mutual exclusivity
  - Added active filter count badge on filter button (shows number of active filter categories)
  - Date range filter moved to VISIBILITY section
  - Reference: `items_home_page.dart:817-1019`

- ✅ **Default stage to Greenware** - Pre-selected on item creation (item_form_state.dart:15)

- ✅ **Display cone value on detail view** - Shows under glaze value (item_detail_page.dart)

- ✅ **Delete Item with cascade** - Deletes item and all photos from GCS (items.py delete_item endpoint)

- ✅ **Fix carousel image display** - Images use BoxFit.contain, no cropping (item_detail_page.dart)

- ✅ **Photo captions/descriptions** - imageNote field editable and displayed (photo.dart, item_detail_page.dart)

- ✅ **Circular radio buttons for stage advancement** - Improved stage selection UI
  - Created StageSelector widget with G/B/F circular radio buttons
  - Shows progression: B selected shows G+B filled, F selected shows G+B+F filled
  - Current stage highlighted with extra border and shadow
  - Added to item detail view for quick stage changes (horizontally arranged with help icon)
  - Enhanced item form dropdown with G/B/F circle icons showing filled/unfilled states
  - Help dialog explains pottery firing stages (Greenware → Bisque → Final)
  - Matches photo overlay badge styling for consistency
  - Loading indicators during stage update (CircularProgressIndicator replaces selector)
  - Loading indicators on broken checkbox (shows spinner, disables checkbox)
  - Prevents double-taps by disabling controls during backend updates
  - Reference: `stage_selector.dart`, `item_detail_page.dart:256-719`, `item_form_page.dart:345-384`

### Previous Session (feature/primary-photo-selection branch)

- ✅ **Fixed production deployment issues** - Resolved Firebase config and backend URL errors
  - Fixed production Firebase config: Android appId was using web appId (caused initialization failure)
  - Fixed version parsing: Now strips build number (+XX) before comparing versions
  - Fixed prod backend URL: Updated to correct Cloud Run URL (pottery-api-prod-4svtnkpwda-uc.a.run.app)
  - Production app now initializes and connects to backend successfully

- ✅ **Photo upload protection** - Prevent accidental photo loss
  - Disabled tap-outside and swipe-down dismissal of upload sheet
  - Added explicit Cancel button in header
  - Shows "Discard Photo?" warning if photo selected and user tries to cancel
  - Only warns if photo has been selected (allows cancel without warning if empty)

- ✅ **Unsaved changes warning** - Prevent accidental data loss when leaving edit screens
  - Added change tracking to item form (all fields: name, clay type, location, glaze, cone, notes, status, measurements, date/time)
  - Added PopScope widget to intercept back navigation
  - Shows dialog with 3 options: "Save and close" / "Discard changes" / "Cancel"
  - Applied to item form page (creates and edits)
  - Applied to photo edit dialog (stage and notes)
  - Tracks dirty state and only warns if changes detected

- ✅ **Interactive deployment script - dev/prod expansion** - Complete cloud deployment support
  - Added environment selection menu: 1) Local/Docker, 2) Dev (Cloud Run), 3) Prod (Cloud Run)
  - Implemented `deploy_backend_dev()` - deploys to Cloud Run dev environment
  - Implemented `deploy_frontend_dev()` - builds and installs dev app with Cloud Run URL
  - Implemented `deploy_backend_prod()` - deploys to Cloud Run prod with safety confirmation
  - Implemented `deploy_frontend_prod()` - builds production app with confirmation dialog
  - Added `check_gcloud_auth()` - verifies gcloud CLI authentication before deployments
  - Added environment-specific completion instructions (show_dev_instructions, show_prod_instructions)
  - Production deployments require typed confirmations: "DEPLOY TO PROD" and "BUILD PROD"
  - Production skips USB installation (signature conflicts, uses Play Store internal testing)
  - Script location: `scripts/deploy.sh` (executable, all environments supported)

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

3. **Implement full-text search** - Search across all fields
   - Search bar for pottery items
   - Search across: name, clay type, location, glaze, notes, cone
   - Real-time search as user types
   - Reference: `frontend/lib/src/features/items/views/items_home_page.dart`

4. Add weight field to measurement details for each pottery stage (greenware, bisque, final)

### Measurement Features

5. Develop camera-based dimension measurement feature for pottery pieces
6. Implement photo analysis for measuring pottery dimensions with reference object
7. Add measurement clarification notes (maximum height, width, depth vs base dimensions)
8. Update measurement UI screens with maximum dimension guidance

### Privacy & Compliance

9. Create privacy policy document for pottery app
10. Implement in-app consent dialogs for data collection
11. Add proper permission request flows for camera and storage access
12. Add transparent data handling disclosures in app UI
13. Implement proper age verification for child privacy protection (if applicable)
14. Add Delete Account button in app settings (link to deletion form)

### Code Quality & Infrastructure

15. **Debug app crashes on photo capture** - Investigate random crashes when "take photo" clicked
   - App sometimes crashes on physical devices during photo capture
   - Investigate camera permission handling
   - Check memory usage during image processing
   - Add crash reporting/logging to identify root cause
   - Test on multiple devices to reproduce consistently
   - Reference: `frontend/lib/src/features/photos/views/photo_upload_sheet.dart`

16. Add comprehensive integration tests for photo upload/delete flow
17. Add unit tests for new Cone field validation
18. Consider adding photo compression before upload to reduce storage costs
19. Implement caching strategy for item list to improve performance

---

## Summary

- **0** tasks in progress
- **33** tasks recently completed (22 from current session)
- **19** tasks pending
  - 2 Firebase/Auth
  - 2 High priority app features
  - 4 Measurement features
  - 6 Privacy/compliance
  - 5 Infrastructure/quality

## Notes

### Current Session Highlights
- **Focus:** Archive/Broken item management, filter UI improvements, stage advancement UX
- **22 tasks completed** (archive/broken system, filters, timestamps, stage selector, plus verified features)
- Implemented complete archive/broken visibility system with mutual exclusivity
- Enhanced filter UI with clear section headers and explanatory text
- Created circular radio button stage selector (G/B/F) with progression display
  - Shows all completed stages filled (B shows G+B, F shows G+B+F)
  - Loading indicators prevent double-taps during backend updates
  - Help dialog explains pottery firing stages
- Enhanced form dropdown with circle icons showing filled/unfilled states
- Fixed timestamp display to show lastUpdatedDateTime instead of createdDateTime
- Added PATCH endpoint for partial item updates (fixes validation errors)
- Added visual badges (amber 'A' for archived, red 'B' for broken)
- Filters now "show only" instead of "include" for clearer behavior
- Active filter count badge shows number of active filter categories
- Loading feedback on broken checkbox prevents double-clicks
- Verified default stage (Greenware), cone display, delete cascade, carousel fixes, and photo captions all working

### General Notes
- Primary photo selection complete: Users can set primary photo via three-dots menu, fullscreen viewer, or photo carousel
- Form fields have been updated: Name (required), Clay Type (optional text), Location (optional), Cone (optional text)
- Scripts consolidated: Infrastructure scripts in `scripts/backend/`, frontend build scripts in `frontend/scripts/`
- Photo deletion bug fixed: Photos now properly persist after delete and re-upload
- Deployment script: `scripts/deploy.sh` (supports local/Docker, dev Cloud Run, prod Cloud Run)
- Unsaved changes protection: Applied to item form and photo edit dialog with smart change detection
