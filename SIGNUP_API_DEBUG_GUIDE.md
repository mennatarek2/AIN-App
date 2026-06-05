# Sign Up API Integration - Debugging Guide

## Overview
I've added comprehensive logging throughout the signup flow to help identify exactly where the issue occurs. This guide will help you trace the signup token through the entire process.

## What I Fixed

### 1. **Added Detailed Logging to Auth Repository** (`auth_repository_impl.dart`)
   - **After Sign Up Step One**: Logs if signup token is extracted and saved
   - **Before OTP Verification**: Logs if signup token is retrieved from storage
   - **After OTP Verification**: Logs success/failure of each step
   - **Error messages**: Now include which step failed

### 2. **Added Logging to API Client** (`api_client.dart`)
   - Logs each POST request path
   - Logs the Authorization Bearer token (first 20 chars for security)
   - Logs HTTP status code for each response
   - Logs error messages with status codes

### 3. **Added Logging to Email Verification Notifier** (`email_verification_notifier.dart`)
   - Logs when verification starts
   - Logs the email and OTP code being sent
   - Logs success or failure with error message

## How to Debug

### Step 1: Run Your App
```bash
flutter run -v  # Verbose mode to see all logs
```

### Step 2: Watch the Console Logs
Look for logs starting with `[AUTH]`, `[API]`, and `[EMAIL_VERIFY]`

### Example Successful Signup Flow

```
[AUTH] Starting signup step one with email: user@example.com
[API] POST /api/Account/signup-stepOne
[API] POST /api/Account/signup-stepOne - Status: 200
[AUTH] Signup step one response received
[AUTH] Extracted signup token: YES (length: 185)
[AUTH] Saving signup token to local storage...
[AUTH] Signup token saved successfully
[AUTH] Verification - Token in storage: YES (length: 185)
```

### Example OTP Verification Flow

```
[EMAIL_VERIFY] Starting email verification for: user@example.com
[EMAIL_VERIFY] OTP Code: 123456
[AUTH] Retrieved signup token: EXISTS (length: 185)
[AUTH] Starting OTP verification with token length: 185
[API] POST /api/Account/verify-otp
[API] Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
[API] POST /api/Account/verify-otp - Status: 200
[AUTH] OTP verified successfully
[AUTH] Completing sign up...
[API] POST /api/Account/complete-signup
[API] Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
[API] POST /api/Account/complete-signup - Status: 200
[AUTH] Sign up completed. Received authToken: YES
[AUTH] Saving session with token length: 185
[AUTH] Session saved and signup token cleared
[EMAIL_VERIFY] Success!
```

## Troubleshooting Guide

### Issue 1: "Signup token missing from signup-stepOne response"
**What to look for:**
```
[AUTH] Extracted signup token: NO
```

**Solutions:**
1. The API response doesn't contain `signupToken` or `authToken` field
2. Check if the response payload structure is different
3. Verify the API documentation response format

**Next step:** Log the full response body in `auth_remote_data_source.dart`:
```dart
Future<AuthSession> signUpStepOne({...}) async {
    final response = await _client.postJson(...);
    print('[DEBUG] Full response: $response');  // Add this
    final session = _parseSession(response);
    ...
}
```

---

### Issue 2: "Retrieved signup token: NULL"
**What to look for:**
```
[AUTH] Retrieved signup token: EXISTS (length: 185)
[AUTH] Starting OTP verification with token length: 185
...
[API] Authorization: Bearer null
```

**Solutions:**
1. The token wasn't saved properly to SharedPreferences
2. SharedPreferences failed silently
3. Different user session

**Test:** Add this check after signup:
```dart
final testToken = await userLocalDataSource.getSignupToken();
print('[DEBUG] Can retrieve token after save: ${testToken != null}');
```

---

### Issue 3: HTTP 401 Unauthorized
**What to look for:**
```
[API] POST /api/Account/verify-otp - Status: 401
[API] Error: 401 - Unauthorized
```

**Solutions:**
1. Authorization header not being sent
   - Check: `[API] Authorization: Bearer ...` log appears
2. Token format incorrect
   - Should be: `Bearer <token>` (with space)
3. Token is expired or invalid
   - Token might have lifetime limit

**Test the header:**
Check if you see the Authorization log line with the correct format.

---

### Issue 4: HTTP 400 Bad Request
**What to look for:**
```
[API] POST /api/Account/verify-otp - Status: 400
[API] Error: 400 - Invalid OTP Code
```

**Solutions:**
1. OTP code is incorrect or expired
2. Request body format wrong
3. Email parameter needed but not sent

**Test:** Manually verify the OTP format:
```dart
print('[DEBUG] OTP before send: $code (length: ${code.length})');
```

---

### Issue 5: HTTP 500 Server Error
**What to look for:**
```
[API] POST /api/Account/verify-otp - Status: 500
[API] Error: 500 - Internal Server Error
```

**Solutions:**
1. Server-side issue
2. Database error saving signup state
3. Email service failure

**Next step:** Contact backend team with:
- The timestamp of the request
- The signup token value (first 20 chars)
- The error message from server logs

---

## Key Data Points to Check

### 1. Token Storage
```dart
// In email_verification_page.dart, add this after signup navigation:
final savedToken = ref.read(authRepositoryProvider).getAuthToken();
print('[DEBUG] Stored auth token: ${savedToken != null ? 'YES' : 'NO'}');
```

### 2. Full Response Inspection
Add to `_parseSession` in `auth_remote_data_source.dart`:
```dart
AuthSession _parseSession(dynamic payload) {
    print('[DEBUG] _parseSession payload: $payload');
    // ... rest of code
}
```

### 3. SharedPreferences Issues
Add to `user_local_data_source.dart`:
```dart
Future<void> saveSignupToken(String token) async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) {
        print('[DEBUG] SharedPreferences returned NULL!');
        return;
    }
    await prefs.setString(_signupTokenKey, token);
    final saved = await prefs.getString(_signupTokenKey);
    print('[DEBUG] Token saved and verified: ${saved == token}');
}
```

## API Endpoint Verification

According to the AIN_API_Documentation.html provided:

| Step | Endpoint | Method | Auth Required | Body |
|------|----------|--------|---------------|------|
| 1 | `/api/Account/signup-stepOne` | POST | No | displayName, userName, email, phoneNumber, ssn, password, confirmPassword |
| 2 | `/api/Account/verify-otp` | POST | **Yes** (Bearer signupToken) | otpCode |
| 3 | `/api/Account/complete-signup` | POST | **Yes** (Bearer signupToken) | (empty) |

✅ **Your endpoints are CORRECT!**

## Testing Checklist

- [ ] Run the app with `flutter run -v`
- [ ] Go through signup process
- [ ] **Copy the logs** from `[AUTH]` section after "Signup step one response received"
- [ ] Verify signup token is extracted: `Extracted signup token: YES`
- [ ] Verify token is saved: `Signup token saved successfully`
- [ ] Enter OTP and check logs
- [ ] Look for Authorization header: `Authorization: Bearer ...`
- [ ] Check HTTP status code of verify-otp request

## Common Mistakes to Avoid

1. ❌ Don't forget to include the `Bearer ` prefix (with space) in Authorization header
   - ✅ Correct: `Authorization: Bearer eyJhbGc...`
   - ❌ Wrong: `Authorization: eyJhbGc...`

2. ❌ Don't reset the signup state prematurely
   - ✅ Only clear signup token after complete signup succeeds
   - ❌ Don't clear it on error

3. ❌ Don't mix auth token and signup token
   - Signup token (for OTP verification): Received from step 1
   - Auth token (for regular requests): Received from step 3

4. ❌ Don't ignore null values
   - ✅ Check `if (token != null && token.isNotEmpty)`
   - ❌ Don't assume token exists

## Next Steps

1. **Run the app with the new logging**
2. **Go through the signup flow completely**
3. **Copy all logs starting with `[AUTH]`, `[API]`, `[EMAIL_VERIFY]`**
4. **Share the logs in your next message**
5. **I'll analyze the logs and identify the exact issue**

Once I see the logs, I can tell you exactly:
- Where the token is being lost
- Whether it's a storage issue or an API request issue
- If the server is rejecting the request and why

## Files Modified

1. `/lib/features/auth/data/repositories/auth_repository_impl.dart` - Added signup token logging
2. `/lib/core/network/api_client.dart` - Added API request/response logging
3. `/lib/features/auth/presentation/notifiers/email_verification_notifier.dart` - Added verification logging

All changes are **debug-only** and won't affect production performance once you remove the print statements.

---

**Ready to test? Run your app and share the logs!** 🚀
