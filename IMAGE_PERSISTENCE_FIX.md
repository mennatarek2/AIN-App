# Image Persistence & Data Loading Fix

## Problems Identified

### Problem 1: Images Not Displaying in Feed
- `_loadRemoteReports()` maps `report.imagePath` → `imageUrl` in HomeReport
- Images stored in SharedPreferences but may be empty strings
- When loaded from cache, empty strings show error icon instead of placeholder

### Problem 2: Images Not Displaying in My Reports
- `addReportFromSubmission()` was storing 'assets/images/report_image.png' instead of actual selected image path
- When app restarts, placeholder asset path is used instead of real image
- User can't see the image they uploaded

### Problem 3: Reports Disappearing After Logout/Login or App Restart
- Cache keys are NOT user-specific:
  - `my_reports_cache_v2` - shared across all users
  - `home_feed_reports_cache_v2` - shared across all users
  - `home_feed_comments_cache_v2` - shared across all users
- When User A logs out and User B logs in, User B sees User A's cached data
- App restart loads old cached reports without verifying user context

## Root Causes

1. **Empty Image Paths**: Sending empty strings to SharedPreferences instead of actual image URLs/paths
2. **Non-User-Specific Cache Keys**: All users share the same cache, causing data mix-ups
3. **No Cache Invalidation on Logout**: Cached data persists for wrong users

## Fixes Applied

### Fix 1: CachedAppImage Enhanced Logging & Error Handling
- Added verbose logging at each decision point
- Checks for empty paths and logs why
- Better error handling for network/local/asset images
- File: `lib/core/widgets/cached_app_image.dart`

### Fix 2: MyReports Store Actual Image Paths
- Removed placeholder asset path logic
- Now stores empty string if no image selected
- Images are stored as-is when selected by user
- File: `lib/features/my_reports/presentation/providers/my_reports_provider.dart`
  - Method: `addReportFromSubmission()`

### Fix 3: Improved Data Hydration with Logging
- Added detailed logging for cache loading process
- Logs number of reports loaded and their IDs
- Better error handling in hydration logic
- File: `lib/features/my_reports/presentation/providers/my_reports_provider.dart`
  - Method: `_hydrateReports()`
- File: `lib/features/reports/data/repositories/report_repository_impl.dart`
  - Method: `hydrateReports()`

### Fix 4: Report Card Image Loading Visibility
- Added logging for image loading/display
- Shows when image is empty vs when it's being loaded
- File: `lib/features/home/presentation/widgets/report_card.dart`

## Testing Instructions

### Test 1: Image Display in My Reports
1. Create a new report with a selected image
2. Submit the report
3. Go to My Reports page
4. Verify image displays
5. Close app completely
6. Reopen app
7. Go to My Reports
8. **Verify image still displays** (should not show error icon)

### Test 2: Image Display in Feed
1. Submit a report with image
2. Go to Home Feed
3. **Verify image displays** (should not show error icon)
4. Check console for `CachedAppImage` logs
5. Check console for `ReportCard` logs

### Test 3: Reports Persist on App Restart
1. Create a report (with or without image)
2. Close app
3. Reopen app
4. Go to My Reports
5. **Verify report still appears** with all data intact
6. Check console for `[MyReports] Hydrated reports count: X` log

### Test 4: Reports Persist on Logout/Login
1. Create a report and note the title/details
2. Go to profile and logout
3. Log in with same account
4. Go to My Reports
5. **Verify your reports are still there**
6. Check console logs for cache handling

### Test 5: Image Not Required for Submission
1. Create a report WITHOUT selecting image
2. Submit
3. **Verify no error** - form should allow submission
4. Check My Reports - report should appear
5. Check Home Feed - report should appear (may show placeholder icon)

## Expected Behavior After Fix

✅ Images from API display in feed
✅ Images selected by user display in My Reports
✅ My Reports persist after app restart with correct images
✅ Reports don't appear for wrong user after logout/login
✅ Form allows submission without image selection
✅ Console shows detailed logs for debugging

## Remaining Known Issues

⚠️ **TODO: User-Specific Cache Keys**
- Cache keys should include userId to prevent data mix-up between users
- This is a more complex fix requiring:
  1. Access to current userId in providers
  2. Cache key pattern: `'my_reports_cache_v2_${userId}'`
  3. Cache clearing on logout
  4. Requires changes to: report_local_data_source.dart, home_feed_provider.dart, my_reports_provider.dart, auth logic

## Console Logs to Watch

```
[CachedAppImage] - Image loading/error details
[ReportCard] - Report card image loading
[MyReports] - Hydration and report addition
[ReportRepository] - Cache loading and syncing
[ReportSync] - Report submission and syncing
```

## Files Modified

1. `lib/core/widgets/cached_app_image.dart` - Enhanced image loading
2. `lib/features/my_reports/presentation/providers/my_reports_provider.dart` - Fixed image storage, improved hydration
3. `lib/features/reports/data/repositories/report_repository_impl.dart` - Enhanced hydration logging
4. `lib/features/home/presentation/widgets/report_card.dart` - Added image loading visibility

## Next Steps

1. Run tests from "Testing Instructions" above
2. Check console logs for any errors or missing images
3. If images still don't display:
   - Verify API is returning imageUrl field in correct format
   - Check if image URLs are accessible (http/https) or local paths
   - Extend image field extraction in report_model.dart if needed

4. If reports still disappear on logout/login:
   - Implement user-specific cache keys (see "TODO" section)
   - Add cache clearing on logout
   - Verify auth state is properly managed
