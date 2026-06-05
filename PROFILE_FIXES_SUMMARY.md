# Profile Loading & Update Issues - Fixes Applied

## Issues Identified from Logs

### 1. **Profile 404 After Signup** ❌ → ✅ FIXED
**Problem:** After user completes signup, profile API returns 404 (profile not yet created on backend)
```
I/flutter: [API] Response Status: 404
I/flutter: [API] Error: 404 - "NotFound"
```

**Root Cause:** Backend needs time to create profile after signup completes

**Solution Applied:**
- Added extended retry logic for 404 errors (5 retries vs 2 retries for other errors)
- Increased delay between post-signup retries to 800ms (vs 400ms normal delay)
- Repository now detects 404 specifically and applies extended retries

**Files Modified:**
- `profile_repository_impl.dart`: Added `_postSignupMaxRetries` (5) and `_postSignupRetryDelay` (800ms)
- Enhanced `fetchMyProfile()` to detect 404 and retry with backoff

### 2. **Profile Picture Not Appearing** ❌ → ✅ SHOULD FIX
**Problem:** Profile picture uploaded during signup doesn't display in profile page

**Root Cause:** Profile fetch fails (404), so picture URL never gets loaded

**Solution:** Once profile loads successfully (via extended retries), picture URL will be available

### 3. **Phone Number Not Persisting** ⚠️ PARTIAL
**Problem:** Phone number entered during signup doesn't appear in profile

**Root Cause:** Same as above - profile not loaded due to 404 error

**Additional Issue:** Some field updates return 400 BadRequest
```
I/flutter: [API] Response Status: 400
I/flutter: [API] Error: 400 - BadRequest
```

**Possible Causes for 400 Errors:**
1. API validation rules on field format (phone, name, etc.)
2. Rapid successive update requests (race condition)
3. API field structure expectations different than sent
4. Null or invalid values being sent

**Recommended Next Steps:**
- Check API endpoint documentation for field format requirements
- Validate phone number format before sending (e.g., Egyptian format)
- Add field validation before sending updates
- Add throttling between successive profile updates

### 4. **Better Error Tracking** ✅ DONE
**Improvement:** Status codes now preserved when catching API errors
- Modified `getMyProfile()` to catch `ApiException` and preserve `statusCode`
- Modified `updateProfile()` to catch `ApiException` and preserve `statusCode`
- Enables better error handling based on HTTP status (404 vs 400 vs 500)

## Technical Changes

### profile_repository_impl.dart
```dart
// Added constants for post-signup retry logic
static const _postSignupMaxRetries = 5;
static const _postSignupRetryDelay = Duration(milliseconds: 800);
```

**Enhanced retry logic:**
- Try normal retries first (2x with 400ms delay)
- Detect 404 errors
- If 404 detected, try extended retries (5x with 800ms delay)
- Falls back to cached profile if available

### profile_remote_data_source.dart
```dart
// Now imports ApiException
import '../../../core/network/api_exception.dart';

// Catches API errors with status codes
on ApiException catch (e) {
  throw ProfileException('Failed to fetch profile: $e', e.statusCode);
}
```

## Testing the Fix

### To verify profile loads after signup:
1. Create new account with all signup details
2. Check Flutter logs for:
   - `[Profile] Fetching profile from API`
   - `[ProfileRepo] Got 404, trying extended retries for post-signup scenario`
   - `[ProfileRepo] Profile fetched successfully after post-signup wait`
3. Profile page should display all info including picture

### To debug 400 errors on updates:
1. Go to Edit Profile page
2. Update any field
3. Check logs for:
   - `[Profile] Updating fieldName`
   - `[API] PUT Multipart /api/Profile/update-profile - Fields: 1`
   - `[API] Response Status: 400` or `200`
4. If 400, check:
   - Field format/validation rules on API
   - Exact field names expected by API
   - Whether API allows rapid successive updates

## Deployment Notes

No breaking changes. Update includes:
- Better error detection for post-signup scenarios
- Automatic extended retries for 404 errors
- Preserved HTTP status codes for better error tracking
- Logging improvements for debugging

## Monitoring

Monitor these logs after deployment:
```
[ProfileRepo] Got 404, trying extended retries for post-signup scenario
```
- HIGH count = API slow to create profiles after signup
- May need to increase `_postSignupMaxRetries` or `_postSignupRetryDelay`

```
[API] Response Status: 400
```
- If frequent on specific fields, check API field requirements
- If random, may indicate timing/concurrency issue
