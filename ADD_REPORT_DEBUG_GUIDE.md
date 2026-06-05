# Add Report Page - Debug & Troubleshooting Guide

## Issues Fixed ✓

### 1. **Error Handling** 
- ✓ Added try-catch block to submit button
- ✓ Error messages now display to user in Arabic
- ✓ Specific error types are detected and translated

### 2. **Loading State**
- ✓ Button shows loading spinner during submission
- ✓ Button is disabled while submitting
- ✓ Prevents duplicate submissions

### 3. **User Feedback**
- ✓ Error snackbar shows what went wrong
- ✓ Success page only shows after confirmation
- ✓ Network errors are caught and displayed

---

## How to Debug Report Submission

### Step 1: Run the App in Debug Mode
```bash
flutter run -v
```

### Step 2: Watch Console Logs
Look for these prefixes:
- `[API]` - Network requests and responses
- `[ReportSync]` - Report sync status
- `[ReportSync] Attempt` - Retry attempts

### Step 3: Test Submission
1. Fill in all required fields
2. Select a category and subcategory
3. Pick/upload an image
4. Select location on map
5. Click "إرسال" button
6. Watch the console for logs

---

## Expected Logs on Success

```
[ReportSync] Creating report (online: true, reportId: xxx)
[ReportSync] Report can be synced - attempting to submit...
[ReportSync] Attempt 1/2 to submit report: xxx
[API] Submitting report:
  Title: Your Title
  Description: Your Description
  SubCategoryId: xxx
  Location: 30.xxx, 31.xxx
  Visibility: Public
  ImagePath: included
  Endpoint: /api/Reports
[API] Response Status: 200
[API] Report submitted successfully. Response: {...}
[ReportSync] Successfully submitted report: xxx
[ReportSync] Report marked as synced: xxx
```

---

## Common Issues & Solutions

### Issue 1: "حدث خطأ أثناء إرسال البلاغ: Missing auth token"
**Problem:** User is not authenticated
**Solution:** 
- User needs to log in first
- Check that token is being saved correctly in auth storage

### Issue 2: "حدث خطأ أثناء إرسال البلاغ: يرجى اختيار التصنيف الفرعي"
**Problem:** SubCategoryId is null or empty
**Solution:**
- Ensure subcategory is properly selected from dropdown
- Verify subCategoryId is mapped correctly in CategoryOption

### Issue 3: "حدث خطأ أثناء إرسال البلاغ: لا يوجد اتصال بالإنترنت"
**Problem:** No internet connection
**Solution:**
- Check device has active internet
- Report is saved locally and will sync when online
- Reports sync automatically when device comes back online

### Issue 4: "حدث خطأ أثناء إرسال البلاغ: فشل الاتصال بالخادم"
**Problem:** API server is unreachable or API returned error
**Solution:**
- Check console logs for detailed API response
- Look for status code in `[API] Response Status: xxx` log
- Verify API endpoint is correct: `/api/Reports`
- Check if server is running and accessible

### Issue 5: Button Shows Loading but Never Completes
**Problem:** Submission is stuck
**Solution:**
- Check console for `[ReportSync] Attempt` logs
- If retrying multiple times, API might be rejecting request
- Look for validation errors in API response in console
- Check network connectivity

---

## How to Read API Logs

### Success Response (Status 200)
```
[API] Response Status: 200
[API] Report submitted successfully. Response: {"id":"xxx","message":"Report created"}
```

### Validation Error (Status 400)
```
[API] Response Status: 400
[API] Error: 400 - Validation error message
[ReportSync] Attempt 1 failed: ApiException: Validation error message
```

### Unauthorized (Status 401)
```
[API] Response Status: 401
[API] Error: 401 - Unauthorized
[ReportSync] Attempt 1 failed: ApiException: Unauthorized
```

### Server Error (Status 500)
```
[API] Response Status: 500
[API] Error: 500 - Internal Server Error
[ReportSync] Attempt 2/3 to submit report (will retry)
```

---

## Report Sync Status

### Report Synced ✓
- Appears in "My Reports" with status "تم الاستلام"
- `isSynced: true` in database
- Server has confirmed receipt

### Report Pending
- Appears in "My Reports" but with "قيد المعالجه" status
- `isSynced: false` in local database
- Will retry syncing when:
  - Device comes online
  - User manually refreshes
  - Background sync runs

---

## Testing Checklist

- [ ] Button shows loading spinner when clicked
- [ ] Button is disabled during submission
- [ ] Success message appears after submission
- [ ] Report appears in "My Reports" list
- [ ] Console shows successful sync logs
- [ ] Image is uploaded with report
- [ ] Location data is sent correctly
- [ ] Category/Subcategory are mapped to IDs correctly
- [ ] Visibility is converted to API format (Public/Anonymous/Confidential)

---

## Report Model Fields Required for API

Field | Type | Required | Example
---|---|---|---
Title | String | ✓ | "حفرة في الطريق"
Description | String | ✓ | "وصف مفصل للمشكلة"
SubCategoryId | UUID | ✓ | "4364b582-d500-4762-80fb-4ef7501a7ec6"
Latitude | Number | ✓ | 30.0452
Longitude | Number | ✓ | 31.2338
Visibility | String | ✓ | "Public" / "Anonymous" / "Confidential"
Image | File | Optional | image.jpg

---

## Backend API Endpoint

- **URL:** `POST /api/Reports`
- **Auth:** Bearer Token required
- **Content-Type:** multipart/form-data
- **Expected Status:** 200 OK
- **Response:** Report object with ID

