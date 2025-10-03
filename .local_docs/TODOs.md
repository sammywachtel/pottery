# Pottery App TODO List

## 🔥 In Progress

*(No tasks currently in progress)*

## ✅ Recently Completed

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

4. **Primary photo selection** - Allow user to select which photo displays in the main pottery item list
   - Add UI to mark a photo as primary (e.g., star icon on photo in detail view)
   - Add `isPrimary` boolean field to Photo model
   - Backend endpoint to update primary photo for item
   - List view displays primary photo, or first photo if none selected
   - Reference: `pottery-backend/backend/models.py`, `pottery-backend/backend/routers/items.py`

5. **Display cone value on item detail view screen** (under glaze value) - Field exists in form, needs to show on detail view
6. **Add modified/updated datetime tracking** - Track when items are edited or photos are added/deleted
7. Add filtering functionality to pottery item list
8. Implement search bar for pottery items (search all fields including descriptions)
9. Add filter options: clay type, location, created/updated date ranges, glaze, status
10. Add description/caption field to photos
11. Add weight field to measurement details for each pottery stage (greenware, bisque, final)

### Measurement Features

12. Develop camera-based dimension measurement feature for pottery pieces
13. Implement photo analysis for measuring pottery dimensions with reference object
14. Add measurement clarification notes (maximum height, width, depth vs base dimensions)
15. Update measurement UI screens with maximum dimension guidance

### Privacy & Compliance

16. Create privacy policy document for pottery app
17. Implement in-app consent dialogs for data collection
18. Add proper permission request flows for camera and storage access
19. Add transparent data handling disclosures in app UI
20. Implement proper age verification for child privacy protection (if applicable)
21. Add Delete Account button in app settings (link to deletion form)

### Code Quality & Infrastructure

22. Add comprehensive integration tests for photo upload/delete flow
23. Add unit tests for new Cone field validation
24. Consider adding photo compression before upload to reduce storage costs
25. Implement caching strategy for item list to improve performance

---

## Summary

- **0** tasks in progress
- **10** tasks recently completed
- **23** tasks pending (9 high priority features, 4 measurement features, 6 privacy/compliance, 4 infrastructure)

## Notes

- Form fields have been updated: Name (required), Clay Type (optional text), Location (optional), Cone (optional text)
- Scripts consolidated: Infrastructure scripts in `scripts/backend/`, frontend build scripts in `frontend/scripts/`
- Photo deletion bug fixed: Photos now properly persist after delete and re-upload
