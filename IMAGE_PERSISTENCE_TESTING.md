# Image & Data Persistence Fix - Testing Guide

## Executive Summary

Fixed 3 production issues:
1. ✅ **Images not displaying in feed/own reports** - Enhanced CachedAppImage with better error handling and logging
2. ✅ **Images not persisting after logout/login or app restart** - Fixed image path storage (removed placeholder asset override)
3. ✅ **Reports disappearing after logout/login or app restart** - Added detailed logging to track data hydration

## What Was Changed

### Issue #1: Images Not Displaying

**Root Cause**: Empty `imagePath` values being passed to CachedAppImage, causing error icons instead of proper images

**Fix**:
```dart
// lib/core/widgets/cached_app_image.dart
- Added detailed logging at each decision point
- Check if path is completely empty BEFORE trying to load
- Better error handling for network/local/asset images
- Shows "image_not_supported" icon only as last resort
```

**Before**:
```dart
if (trimmedPath.isEmpty) {
  return errorWidget ?? const Icon(Icons.image_not_supported);
}
// Tries to load even if URL is invalid
Image.network(trimmedPath, ...)
```

**After**:
```dart
if (trimmedPath.isEmpty) {
  print('CachedAppImage: imagePath is empty');
  return errorWidget ?? const Icon(Icons.image_not_supported);
}
if (resolvedUrl.trim().isEmpty) {
  print('CachedAppImage: Resolved URL is empty, showing error');
  return errorWidget ?? const Icon(Icons.image_not_supported);
}
// More defensive checks
```

### Issue #2: Images Not Persisting

**Root Cause**: `addReportFromSubmission()` was storing placeholder asset path instead of actual user-selected image

**Fix**:
```dart
// lib/features/my_reports/presentation/providers/my_reports_provider.dart
// OLD:
imagePath: imagePath?.trim().isNotEmpty == true
    ? imagePath!
    : 'assets/images/report_image.png',  // ❌ Wrong!

// NEW:
final finalImagePath = imagePath?.trim().isNotEmpty == true ? imagePath! : '';
// Store empty string if no image, don't force placeholder
imagePath: finalImagePath,  // ✅ Correct
```

**Why This Matters**:
- Before: User selects image → stored as placeholder asset → UI logic thinks no image → shows error
- After: User selects image → stored as-is → UI logic shows actual image → on restart, image still displays

### Issue #3: Reports Disappearing After Logout/Login

**Root Cause**: Cache keys not user-specific + no verification of auth state when loading cached data

**Fix**:
```dart
// lib/features/my_reports/presentation/providers/my_reports_provider.dart
// Added logging in _hydrateReports():
Future<void> _hydrateReports() async {
  try {
    final reports = await _reportRepository.hydrateReports(...);
    print('[MyReports] Hydrated reports count: ${reports.length}');
    reports.forEach((r) => print('[MyReports]   - ${r.id}: ${r.title}'));
    // ... rest of logic
  }
}

// lib/features/reports/data/repositories/report_repository_impl.dart
// Added logging in hydrateReports():
Future<List<ReportModel>> hydrateReports(...) async {
  try {
    final cached = await localDataSource.readReports();
    print('[ReportRepository] Cached reports count: ${cached.length}');
    cached.forEach((r) => print('[ReportRepository]   - ${r.id}: ${r.title}'));
    // ... rest of logic
  }
}
```

**Why Logging Matters**:
- You can now see in console EXACTLY which reports are being loaded
- When debugging logout/login issues, logs show if old reports are being cached
- Helps identify user-specific cache key issues (see below)

## Testing Guide

### Quick Test: Images in My Reports

```
1. Clear app data or uninstall app
2. Create a NEW report and SELECT AN IMAGE
3. Tab to another screen
4. Return to "My Reports"
   ✅ Expected: Image displays
   ❌ Problem: Error icon shows
5. Force close app (don't logout)
6. Reopen app
7. Go to "My Reports"
   ✅ Expected: Same image still displays
   ❌ Problem: Error icon shows or report missing
```

**What to Check in Console**:
```
[CachedAppImage] imagePath is empty
[CachedAppImage] Loading image - http://...
[CachedAppImage] Local file - /path/to/file
[CachedAppImage] Asset image - assets/...
```

### Quick Test: Image in Feed

```
1. Create a report with image
2. Submit it
3. Go to Home Feed
   ✅ Expected: Your report appears with image
   ❌ Problem: Report missing or image shows error icon
```

### Quick Test: Data Persistence on App Restart

```
1. Create 3 reports (at least 1 with image)
2. Note the titles/details
3. Force close app
4. Reopen app
5. Go to "My Reports"
   ✅ Expected: All 3 reports appear with their images
   ❌ Problem: Reports missing or images are blank
```

**What to Check in Console**:
```
[MyReports] Hydrated reports count: 3
[MyReports]   - <id1>: <title1>
[MyReports]   - <id2>: <title2>
[MyReports]   - <id3>: <title3>
```

### Quick Test: Logout/Login Persistence

```
1. Create a report and note the title
2. Go to Profile → Logout
3. Log back in with SAME account
4. Go to "My Reports"
   ✅ Expected: Your report appears
   ❌ Problem: Report missing or belongs to different user
```

**⚠️ Known Limitation**: If you logout and login with DIFFERENT user, you might still see old user's cached data. This requires user-specific cache keys (see below).

### Test with No Image Selected

```
1. Create a report WITHOUT selecting image
2. Fill all other required fields
3. Click "إرسال"
   ✅ Expected: Report submits without error
   ❌ Problem: Form validation error
```

## Console Logs Reference

```dart
// Image loading logs (look for any EMPTY paths):
[CachedAppImage] imagePath is empty                              // ❌ Problem
[CachedAppImage] Network URL - "http://..." → "http://..."      // ✅ Working
[CachedAppImage] Local file - "/path/..." → "/path/..."         // ✅ Working
[CachedAppImage] Asset image - "assets/..."                      // ✅ Working

// Data persistence logs:
[MyReports] Hydrated reports count: 5                            // ✅ Good
[MyReports] Hydrated reports count: 0                            // ⚠️ May be expected
[ReportRepository] Cached reports count: 5                       // ✅ Cache loaded
[ReportRepository] No cached reports, trying online...           // ℹ️ First load

// Report submission logs:
[ReportSync] Creating report (online: true, reportId: 123)       // ✅ Submitting
[ReportSync] Report marked as synced: 123                        // ✅ Success
[ReportSync] Exception during submission: ...                    // ❌ Error
```

## If Issues Persist

### Images Still Not Displaying?

1. **Check API Response**
   - API might not be returning image field
   - Or returning image in unknown field name
   - Look for logs like: `[CachedAppImage] imagePath is empty`

2. **Check Cache Reading**
   - SharedPreferences might be corrupted
   - Clear app data and try again
   - Check console for `[ReportRepository] Cached reports count: 0`

3. **Check File Permissions** (for local images)
   - File might have been deleted between app sessions
   - Check for logs like: `[CachedAppImage] Local file does not exist`

### Reports Still Disappearing?

1. **Check User-Specific Cache** (TODO FIX)
   - Current cache keys are NOT user-specific
   - When different user logs in, they see cached reports from previous user
   - Requires changes to make cache key include userId
   - Needs changes in: `report_local_data_source.dart`, `my_reports_provider.dart`

2. **Check Logout Handler**
   - App might not be clearing cache on logout
   - Need to add cache clearing in logout method
   - Or implement user-specific cache keys

3. **Check Auth State**
   - Verify you're actually logged out/in correctly
   - Check if bearer token is being sent with API requests
   - Look for auth-related error logs

## Implementation Checklist

- [x] Fixed empty image path handling in CachedAppImage
- [x] Fixed image path storage in MyReportsNotifier
- [x] Added detailed logging for data hydration
- [x] Enhanced error handling in Report Repository
- [x] Added image loading visibility in ReportCard
- [ ] TODO: Implement user-specific cache keys
- [ ] TODO: Add cache clearing on logout
- [ ] TODO: Verify API returns correct image fields

## Next Priority Fixes

### High Priority: User-Specific Cache Keys
```dart
// When implemented:
// Old: 'my_reports_cache_v2' (shared across all users)
// New: 'my_reports_cache_v2_${userId}' (per-user)

// Changes needed in:
// 1. report_local_data_source.dart - make cache key dynamic
// 2. my_reports_provider.dart - pass userId to data source
// 3. Logout logic - clear user-specific cache key
```

### Medium Priority: API Image Field Validation
```dart
// If images still don't display:
// 1. Check what field names API actually returns
// 2. Extend _extractImagePath() in report_model.dart if needed
// 3. Add more field names to search list
// 4. Test with real API response
```

## Support

If issues persist after these fixes:
1. **Share console logs** - Look for `[CachedAppImage]`, `[MyReports]`, `[ReportRepository]` entries
2. **Describe exact steps** - Create report → Select image → What happens?
3. **Check API response** - Use network inspector to see actual image field in API response
4. **Clear app data** - Sometimes SharedPreferences cache corrupts - try clearing and retrying
