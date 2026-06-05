# Image & Data Persistence Debugging Guide

## Problem Statement

User reported 3 production issues:
1. **"الصور موجوده ميتتعرض في feed"** - Images not displaying in feed
2. **"لو انا عملت ريبورت من اكونتي مبيتعرض فيه الصوره"** - Images not displaying in own created reports
3. **"لو سجلت خروج ودخلت تاني او قفلت الابلكيشن وفتحته مبيتعرض ليا البلاغات"** - Reports missing after logout/login or app restart

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│  User Actions                                               │
│  1. Create report with image                                │
│  2. Submit report                                           │
│  3. Close app / Logout                                      │
│  4. Reopen app / Login                                      │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────▼────────────┐
        │  Add Report UI         │
        │  add_report_page.dart  │
        │  _selectedImage        │
        └────────────┬───────────┘
                     │ (imagePath)
        ┌────────────▼──────────────────┐
        │  MyReportsProvider            │
        │  addReportFromSubmission()    │  ← IMAGE STORAGE HAPPENS HERE
        │  Store to Repository         │
        └────────────┬──────────────────┘
                     │ (imagePath)
        ┌────────────▼─────────────────────┐
        │  ReportRepository               │
        │  createReport()                 │
        │  Save local + submit remote     │
        └────────────┬─────────────────────┘
                     │
     ┌───────────────┴───────────────┐
     │ (Local Save)  │  (Remote Submit)
     │               │
┌────▼─────────┐  ┌──▼──────────────┐
│SharedPrefs   │  │  API Server      │
│'my_reports_  │  │  Store report    │
│cache_v2'     │  │  Store image URL │
└────┬─────────┘  └──┬──────────────┘
     │                │
     └───────────────┬─┘
                     │
        ┌────────────▼────────────┐
        │  Data Reload (on restart)
        │  _hydrateReports()      │  ← DATA RETRIEVAL
        └────────────┬────────────┘
                     │
        ┌────────────▼──────────────────┐
        │  CachedAppImage Widget       │
        │  Display image or error icon │  ← IMAGE DISPLAY
        └────────────────────────────────┘
```

## Issue #1: Images Not Displaying in Feed

### Flow Diagram

```
API Returns Report
├─ id: "123"
├─ title: "تقرير"
├─ imageUrl: "http://api.com/images/report.jpg"  ✓ or empty ✗
└─ ... other fields

        ↓

HomeReport.fromJson() called
├─ _extractImageUrl(json)
└─ Searches these keys in order:
   1. 'imageUrl'        ← Usually found here
   2. 'imagePath'
   3. 'attachmentUrl'
   ... 20+ more keys
   └─ Returns first non-empty match or ''

        ↓

HomeReport created
├─ id: "123"
├─ title: "تقرير"
├─ imageUrl: "http://..." or ""  ← CRITICAL: Empty means no image
└─ ... other fields

        ↓

ReportCard renders
├─ CachedAppImage(imagePath: imageUrl)
└─ imageUrl is empty → Shows error icon ✗
   imageUrl has URL → Tries to load image ✓

        ↓

CachedAppImage.build()
├─ if (imagePath.isEmpty)
│  └─ Show error icon ✗
├─ if (_isNetworkUrl(imagePath))
│  └─ Image.network(imagePath) ✓
└─ else
   └─ Try local/asset ✓
```

### Debug Steps

**Step 1: Check API Response**
```dart
// Add logging in home_feed_provider.dart, _loadRemoteReports()
print('[HomeFeed] Raw API response:');
for (final report in remote) {
  print('[HomeFeed]   Report ID: ${report.id}');
  print('[HomeFeed]   Title: ${report.title}');
  print('[HomeFeed]   ImagePath: "${report.imagePath}"');  // ← WATCH THIS
}
```

**Step 2: Check Image Extraction**
```dart
// Add logging in HomeReport._extractImageUrl()
print('[ImageExtraction] Searching for image in report: ${json.keys}');
// ... loop through keys ...
print('[ImageExtraction] Found image: "$value"');
// or
print('[ImageExtraction] No image found, returning ""');
```

**Step 3: Check CachedAppImage**
```dart
// Already added in the fix:
print('CachedAppImage: imagePath is empty');
print('CachedAppImage: Network URL - "$trimmedPath" → "$resolvedUrl"');
print('CachedAppImage: Local file - "$trimmedPath" → "$normalized"');
print('CachedAppImage: Asset image - "$trimmedPath"');
```

**Expected vs Actual**:
```
✅ EXPECTED:
[HomeFeed] Raw API response:
[HomeFeed]   Report ID: 123
[HomeFeed]   Title: تقرير
[HomeFeed]   ImagePath: "http://api.com/images/report.jpg"
[CachedAppImage] Network URL - "http://api.com/images/report.jpg" → "..."

❌ ACTUAL (Problem):
[HomeFeed] Raw API response:
[HomeFeed]   Report ID: 123
[HomeFeed]   Title: تقرير
[HomeFeed]   ImagePath: ""                                        ← Problem here
[CachedAppImage] imagePath is empty
```

## Issue #2: Images Not Persisting in My Reports

### Flow Diagram

```
User Selects Image
├─ Image picked from gallery/camera
└─ _selectedImage = File(/storage/emulated/.../photo.jpg)

        ↓

Form Submitted
├─ submit() calls addReportFromSubmission(imagePath: selectedImage.path)
└─ imagePath = "/storage/emulated/.../photo.jpg"

        ↓

OLD CODE (WRONG):  ❌
├─ Report created with:
│  imagePath: imagePath?.trim().isNotEmpty == true
│             ? imagePath!
│             : 'assets/images/report_image.png'  ← WRONG!
└─ Result: If user selected image, stored as "/storage/..."
          If no image, stored as "assets/..."
          But later logic might replace with asset!

        ↓

NEW CODE (FIXED):  ✓
├─ finalImagePath = imagePath?.trim().isNotEmpty == true ? imagePath! : ''
├─ Report created with:
│  imagePath: finalImagePath
└─ Result: If user selected image, stored as "/storage/..."
          If no image, stored as ""
          No placeholder override!

        ↓

Report Saved to SharedPreferences
├─ Serialize to JSON with imagePath value
└─ Store in 'my_reports_cache_v2'

        ↓

App Closed & Reopened
├─ _hydrateReports() loads from cache
├─ Read JSON from 'my_reports_cache_v2'
├─ Deserialize to ReportModel
│  ├─ if imagePath = "/storage/..." → Load local file ✓
│  ├─ if imagePath = "" → Show error icon ✗ (but this is expected)
│  └─ if imagePath = "assets/..." → Load asset ✓
└─ CachedAppImage displays image or error icon

```

### What Changed

**Before**:
```dart
imagePath: imagePath?.trim().isNotEmpty == true
    ? imagePath!
    : 'assets/images/report_image.png',
```

This means:
- User selects image → stored as "/storage/..."
- No image selected → stored as "assets/..."
- **Problem**: Later code might not handle "assets/..." correctly, or it might be used inconsistently

**After**:
```dart
final finalImagePath = imagePath?.trim().isNotEmpty == true ? imagePath! : '';

imagePath: finalImagePath,
```

This means:
- User selects image → stored as "/storage/..." ✓
- No image selected → stored as "" ✓
- **Better**: Consistent handling - either real image or empty, no placeholder confusion

### Debug Steps

**Step 1: Check Image Selection**
```dart
// In add_report_page.dart, _pickImage():
print('[ImagePicker] Selected image path: "${pickedFile.path}"');
print('[ImagePicker] File exists: ${File(pickedFile.path).existsSync()}');
```

**Step 2: Check Image Storage**
```dart
// In my_reports_provider.dart, addReportFromSubmission():
print('[MyReports] Storing image path: "$finalImagePath"');
print('[MyReports] Image path is empty: ${finalImagePath.isEmpty}');
```

**Step 3: Check Cache Save**
```dart
// In report_local_data_source.dart, saveReports():
print('[LocalCache] Saving ${reports.length} reports');
for (final report in reports) {
  print('[LocalCache]   - ${report.id}: imagePath="${report.imagePath}"');
}
```

**Step 4: Check Cache Load**
```dart
// In report_local_data_source.dart, readReports():
final loaded = ...
print('[LocalCache] Loaded ${loaded.length} reports');
for (final report in loaded) {
  print('[LocalCache]   - ${report.id}: imagePath="${report.imagePath}"');
}
```

**Expected Flow**:
```
1. User picks image: "/storage/emulated/0/DCIM/photo.jpg"
2. Submit report:    "[MyReports] Storing image path: "/storage/emulated/0/DCIM/photo.jpg"
3. Save to cache:    "[LocalCache] Saving 1 reports - imagePath="/storage/emulated/0/DCIM/photo.jpg"
4. App restarts
5. Load from cache:  "[LocalCache] Loaded 1 reports - imagePath="/storage/emulated/0/DCIM/photo.jpg"
6. Display image:    Image.file("/storage/emulated/0/DCIM/photo.jpg") shows image ✓
```

**Problem Flow**:
```
1. User picks image: "/storage/emulated/0/DCIM/photo.jpg"
2. Submit report:    "[MyReports] Storing image path: ""  ← WRONG! Image lost
3. Save to cache:    "[LocalCache] Saving 1 reports - imagePath=""
4. App restarts
5. Load from cache:  "[LocalCache] Loaded 1 reports - imagePath=""
6. Display image:    CachedAppImage shows error icon ✗
```

## Issue #3: Reports Disappearing After Logout/Login or App Restart

### Flow Diagram - MULTIPLE USERS

```
USER A (logged in)
└─ Creates reports
   └─ Stored in cache with key: 'my_reports_cache_v2'
   └─ SharedPreferences content:
      {
        'my_reports_cache_v2': '[{"id":"A1",...}, {"id":"A2",...}]'
      }

        ↓ (User A logs out)

        ↓ (User B logs in)

USER B (logged in)
└─ SharedPreferences STILL contains User A's data!
   └─ Cache key is NOT user-specific: 'my_reports_cache_v2'
   └─ When _hydrateReports() is called:
      ├─ Read from 'my_reports_cache_v2'
      ├─ Gets User A's reports!  ← PROBLEM
      └─ User B sees User A's data

        ↓ (User B creates reports)

USER B (continues session)
└─ Stored in cache with key: 'my_reports_cache_v2'
   └─ Overwrites User A's data
   └─ SharedPreferences content:
      {
        'my_reports_cache_v2': '[{"id":"B1",...}, {"id":"B2",...}]'
      }

        ↓ (User B logs out)

USER A (logs back in)
└─ SharedPreferences now contains User B's data!
   └─ When _hydrateReports() is called:
      ├─ Read from 'my_reports_cache_v2'
      ├─ Gets User B's reports!  ← WRONG
      └─ User A sees User B's data
```

### Root Cause

**BEFORE** (Current Code):
```dart
// report_local_data_source.dart
static const _cacheKey = 'my_reports_cache_v2';  // ← Same for ALL users
```

**AFTER** (Should be):
```dart
// report_local_data_source.dart
String _cacheKey(String userId) => 'my_reports_cache_v2_$userId';  // ← Per-user

// Usage:
final key = _cacheKey(currentUserId);
await prefs.setString(key, jsonEncode(reports));
```

### Current Behavior - Workaround

The fix added detailed logging so you can see EXACTLY what's happening:

```dart
// MY REPORTS HYDRATION LOGS:
[MyReports] Hydrated reports count: 5
[MyReports]   - report1: "Title 1"
[MyReports]   - report2: "Title 2"
... etc
```

**What to check**:
1. Create report as User A
2. See in console: `[MyReports] Hydrated reports count: 1` with report ID
3. Logout and login as User B
4. Check console:
   - ✅ GOOD: `[MyReports] Hydrated reports count: 0` (no reports for User B)
   - ❌ PROBLEM: `[MyReports] Hydrated reports count: 1` (User A's reports appearing)

## Console Log Reference

### Complete Debug Output Example

```
========== CREATE REPORT WITH IMAGE ==========
[ImagePicker] Selected image path: "/storage/emulated/0/DCIM/photo.jpg"
[ImagePicker] File exists: true

[AddReportPage] Submit clicked
[ReportSync] Creating report (online: true, reportId: <new-id>)
[MyReports] Storing image path: "/storage/emulated/0/DCIM/photo.jpg"
[MyReports] Report stored - ID: <report-id>, ImagePath: "/storage/emulated/0/DCIM/photo.jpg"
[ReportSync] Attempt 1/2 to submit report: <report-id>
[ReportSync] Successfully submitted report: <report-id>
[ReportSync] Report marked as synced: <report-id>

[MyReports] Hydrated reports count: 1
[MyReports]   - <report-id>: "Report Title"

========== VIEW MY REPORTS ==========
[CachedAppImage] Network URL - "file:///storage/emulated/0/DCIM/photo.jpg" → "/storage/emulated/0/DCIM/photo.jpg"
✓ Image displays in UI

========== CLOSE & REOPEN APP ==========
[MyReports] Hydrated reports count: 1
[MyReports]   - <report-id>: "Report Title"
[ReportRepository] Cached reports count: 1
[CachedAppImage] Local file - "/storage/emulated/0/DCIM/photo.jpg" → "/storage/emulated/0/DCIM/photo.jpg"
✓ Image still displays

========== LOGOUT & LOGIN AS DIFFERENT USER ==========
[Logout] Called
[Login] User B logged in
[MyReports] Hydrated reports count: ??? 
[MyReports]   - ... (depends on implementation)
```

## Key Metrics to Check

```
✅ GOOD Signs:
- imagePath has actual path (not empty) before caching
- Hydrated reports count matches created reports
- Same report IDs appear after app restart
- CachedAppImage shows "Network URL -" or "Local file -" (not just "imagePath is empty")

❌ BAD Signs:
- imagePath is empty when storing report
- Hydrated reports count is 0 after creating reports
- Different report IDs appear after logout/login
- CachedAppImage shows "imagePath is empty" repeatedly
- Persistent "image_not_supported" icons in feed
```

## Next Steps for Testing

1. **Enable all console logging**
   - Add breakpoint in each method
   - Check console output during each step

2. **Create reports with images** and watch logs:
   - Does imagePath get stored correctly?
   - Does cache save succeed?
   - Does cache load on restart?

3. **Test logout/login** and watch logs:
   - Are correct reports loaded?
   - Are old user reports still in cache?

4. **If images still missing**:
   - Check if API is returning imageUrl field
   - Check if image URLs are valid (try opening in browser)
   - Check if local files still exist after app restart

5. **If reports still disappearing**:
   - Implement user-specific cache keys (see Issue #3 solution)
   - Add cache clearing on logout
   - Verify auth state when loading from cache
