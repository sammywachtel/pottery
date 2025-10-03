# Pottery App TODO List

## 🔥 In Progress

*(No tasks currently in progress)*

## ✅ Recently Completed

- ✅ **Primary photo selection** - Allow user to select which photo displays in the main pottery item list
  - Added `isPrimary` boolean field to Photo model (backend + frontend)
  - Added PATCH endpoint `/api/items/{item_id}/photos/{photo_id}/primary`
  - Added "Set as primary" option in photo card three-dots menu
  - Added star button in fullscreen photo viewer
  - List view displays primary photo, or most recent photo if none selected
  - Backend auto-sets first uploaded photo as primary if none selected
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

3. **🔴 Fix photo flickering during scroll** - Photos keep disappearing and refreshing during list scrolling, causing poor UX
   - Implement `cached_network_image` package for disk/memory caching
   - Use `AutomaticKeepAliveClientMixin` on list item widgets
   - Add `cacheExtent` to ListView for preloading off-screen items
   - Consider serving thumbnails instead of full images in list view
   - Reference: `pottery-backend/backend/services/gcs_service.py`

4. **Display last updated date on item list screen** - Show last updated date instead of created date
   - Show the most recent date between item update and photo upload
   - Consider showing both created and updated dates (e.g., "Updated 2d ago")
   - Reference: `frontend/lib/src/features/items/views/items_home_page.dart` (_PotteryItemCard)

5. **Quick stage advancement** - Add quick method to change item stage on detail view screen
   - Add stage selector/stepper at top of item detail view (near current status badge)
   - Allow quick stage advancement: Greenware → Bisque → Final
   - Show confirmation dialog before changing stage
   - Consider adding timestamps for each stage transition
   - Reference: `frontend/lib/src/features/items/views/item_detail_page.dart`

6. **Default stage to Greenware on create/edit screen** - Pre-select Greenware as default stage
   - Set "Greenware" as default value in item form dropdown/selector
   - Saves user from having to remember to select it every time
   - Most pottery starts at greenware stage
   - Reference: `frontend/lib/src/features/items/views/item_form_page.dart`

7. **Warn about unsaved changes** - Prevent accidental data loss when leaving edit screens
   - Detect if form has unsaved changes (use Form dirty state tracking)
   - Show dialog when user tries to navigate back or close screen
   - Dialog options: "Save and close" / "Discard changes" / "Cancel"
   - Apply to both item form and photo edit dialogs
   - Reference: `frontend/lib/src/features/items/views/item_form_page.dart`, `item_detail_page.dart`

8. **Display cone value on item detail view screen** (under glaze value) - Field exists in form, needs to show on detail view

9. **Add modified/updated datetime tracking** - Track when items are edited or photos are added/deleted

10. Add filtering functionality to pottery item list

11. Implement search bar for pottery items (search all fields including descriptions)

12. Add filter options: clay type, location, created/updated date ranges, glaze, status

13. Add description/caption field to photos

14. Add weight field to measurement details for each pottery stage (greenware, bisque, final)

### Measurement Features

15. Develop camera-based dimension measurement feature for pottery pieces
16. Implement photo analysis for measuring pottery dimensions with reference object
17. Add measurement clarification notes (maximum height, width, depth vs base dimensions)
18. Update measurement UI screens with maximum dimension guidance

### Privacy & Compliance

19. Create privacy policy document for pottery app
20. Implement in-app consent dialogs for data collection
21. Add proper permission request flows for camera and storage access
22. Add transparent data handling disclosures in app UI
23. Implement proper age verification for child privacy protection (if applicable)
24. Add Delete Account button in app settings (link to deletion form)

### Code Quality & Infrastructure

25. Add comprehensive integration tests for photo upload/delete flow
26. Add unit tests for new Cone field validation
27. Consider adding photo compression before upload to reduce storage costs
28. Implement caching strategy for item list to improve performance

### DevOps & Deployment

29. **Create interactive master deployment script** - Unified deployment workflow for all environments
    - **Environment selection**: Ask user to choose local/dev/prod environment
    - **Deployment target selection**: Ask what to deploy (1. Backend Only, 2. Frontend Only, 3. Both)
    - **USB phone detection**: Automatically detect connected Android device and install if present. Always deploy the
        phone if detected and ensure that the environment is part of the name of the app on the side-loaded app.
        (e.g, "Pottery Studio Docker SL", "Pottery Studio Dev SL" where SL is for side loaded)
    - **Auto-build AAB**: Always build app bundle when frontend is included (no need to remember)
    - **Post-deployment instructions**: Show next steps after completion
      - Where to find AAB for Google Play upload (`frontend/build/app/outputs/bundle/`)
      - How to use the deployed system
      - Testing instructions for each environment
    - **Authentication verification**: For cloud deployments (dev/prod backend)
      - Check if user is logged in with `gcloud auth list`
      - Verify account has required IAM roles (documented in `backend/docs/how-to/setup-production.md`)
      - Prompt user to login with correct account if needed
      - List required roles: Cloud Run Admin, Artifact Registry Writer, etc.
    - **Reference**: Existing scripts in `scripts/backend/` and `frontend/scripts/`
    - **Location**: Create at `scripts/deploy.sh` (project root)

---

## Summary

- **0** tasks in progress
- **11** tasks recently completed
- **29** tasks pending
  - 2 Firebase/Auth
  - 12 High priority app features
  - 4 Measurement features
  - 6 Privacy/compliance
  - 4 Infrastructure/quality
  - 1 DevOps/deployment

## Notes

- Primary photo selection complete: Users can set primary photo via three-dots menu or fullscreen viewer
- Form fields have been updated: Name (required), Clay Type (optional text), Location (optional), Cone (optional text)
- Scripts consolidated: Infrastructure scripts in `scripts/backend/`, frontend build scripts in `frontend/scripts/`
- Photo deletion bug fixed: Photos now properly persist after delete and re-upload
