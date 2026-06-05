# Sign Up API Integration - Implementation Status & Next Steps

## Summary of Changes

I've analyzed your signup flow and added comprehensive logging throughout the signup process. The code structure looks **correct**, but we need to see the actual error to fix it.

## What I've Done

### ✅ Added Debug Logging in 3 Key Files

#### 1. **auth_repository_impl.dart** - Signup Token Tracking
```dart
// After Sign Up Step One
[AUTH] Starting signup step one with email: user@example.com
[AUTH] Signup step one response received
[AUTH] Extracted signup token: YES (length: 185)
[AUTH] Saving signup token to local storage...
[AUTH] Signup token saved successfully
[AUTH] Verification - Token in storage: YES (length: 185)

// During OTP Verification
[AUTH] Retrieved signup token: EXISTS (length: 185)
[AUTH] Starting OTP verification with token length: 185
[AUTH] OTP verified successfully
[AUTH] Completing sign up...
[AUTH] Sign up completed. Received authToken: YES
[AUTH] Saving session with token length: 185
[AUTH] Session saved and signup token cleared
```

#### 2. **api_client.dart** - API Request/Response Logging
```dart
[API] POST /api/Account/verify-otp
[API] Authorization: Bearer eyJhbGciOiJIUzI1NiIsI...
[API] POST /api/Account/verify-otp - Status: 200
// or
[API] POST /api/Account/verify-otp - Status: 401
[API] Error: 401 - Unauthorized
```

#### 3. **email_verification_notifier.dart** - Verification Flow Logging
```dart
[EMAIL_VERIFY] Starting email verification for: user@example.com
[EMAIL_VERIFY] OTP Code: 123456
[EMAIL_VERIFY] Success!
// or
[EMAIL_VERIFY] ERROR: Invalid OTP Code
```

## How the Fix Works

### The Signup Process (Corrected Flow)

```
┌─────────────────────────────────────────────┐
│ 1. Sign Up Step One                         │
│ POST /api/Account/signup-stepOne            │
│ Body: displayName, userName, email, etc.    │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
            ✅ Response has signupToken
                      │
                      ▼
        Save signupToken to SharedPreferences
                      │
                      ▼
┌─────────────────────────────────────────────┐
│ 2. Email Verification Page                  │
│ User enters OTP code from email             │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
    GET signupToken from SharedPreferences
                      │
                      ▼
┌─────────────────────────────────────────────┐
│ 3. Verify OTP                               │
│ POST /api/Account/verify-otp                │
│ Headers: Authorization: Bearer signupToken  │
│ Body: { "otpCode": "123456" }               │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
            ✅ Response status 200
                      │
                      ▼
┌─────────────────────────────────────────────┐
│ 4. Complete Sign Up                         │
│ POST /api/Account/complete-signup           │
│ Headers: Authorization: Bearer signupToken  │
│ Body: (empty)                               │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
    ✅ Response has authToken
                      │
                      ▼
        Save authToken to SharedPreferences
        Clear signupToken from SharedPreferences
                      │
                      ▼
    ✅ Navigate to next screen (ID Verification)
```

## Code Architecture

### Authorization Header Implementation
**File:** `lib/core/network/api_client.dart`

```dart
Map<String, String> _headers({String? token, bool json = true}) {
  final headers = <String, String>{'Accept': 'application/json'};
  if (json) {
    headers['Content-Type'] = 'application/json';
  }
  if (token != null && token.trim().isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';  // ✅ Correct format
  }
  return headers;
}
```

### Remote Data Source (API Calls)
**File:** `lib/features/auth/data/data_sources/auth_remote_data_source.dart`

```dart
Future<void> verifyOtp({
  required String otpCode,
  required String signupToken,
}) async {
  await _client.postJson(
    ApiEndpoints.verifyOtp,
    token: signupToken,  // ✅ Passed as token parameter
    body: {'otpCode': otpCode},
  );
}

Future<AuthSession> completeSignUp({required String signupToken}) async {
  final response = await _client.postJson(
    ApiEndpoints.completeSignUp,
    token: signupToken,  // ✅ Passed as token parameter
  );
  return _parseSession(response);
}
```

### Repository (Token Management)
**File:** `lib/features/auth/data/repositories/auth_repository_impl.dart`

```dart
@override
Future<Either<AuthFailure, void>> verifyEmail({
  required String email,
  required String code,
}) async {
  try {
    // ✅ Retrieve signup token from local storage
    final signupToken = await userLocalDataSource.getSignupToken();
    
    // ✅ Call verify OTP with token
    await remoteDataSource.verifyOtp(otpCode: code, signupToken: signupToken);
    
    // ✅ Call complete signup with token
    final session = await remoteDataSource.completeSignUp(signupToken: signupToken);
    
    // ✅ Save auth token from response
    final token = session.authToken;
    if (token != null && token.trim().isNotEmpty) {
      await userLocalDataSource.saveSession(user: user, token: token);
    }
    
    return const Right(null);
  } catch (e) {
    return Left(_handleException(e));
  }
}
```

## Potential Issues & Solutions

### Issue 1: Signup Token Not Saved
**Check logs for:**
```
[AUTH] Verification - Token in storage: NO
```
**Solution:** Add this to `user_local_data_source.dart`:
```dart
Future<void> saveSignupToken(String token) async {
  final prefs = await _safeGetPrefs();
  if (prefs == null) {
    print('[ERROR] SharedPreferences is NULL!');
    return;
  }
  await prefs.setString(_signupTokenKey, token);
  final saved = await prefs.getString(_signupTokenKey);
  print('[DEBUG] Token persisted: ${saved == token}');
}
```

### Issue 2: 401 Unauthorized Response
**Check logs for:**
```
[API] POST /api/Account/verify-otp - Status: 401
[API] Error: 401 - Unauthorized
```
**Solution:** This means:
1. ❌ Token is not being sent
2. ❌ Token format is wrong
3. ✅ Token is valid but expired

**Check:**
- Does log show `[API] Authorization: Bearer ...`?
- Is the token length reasonable (100+ chars)?

### Issue 3: 400 Bad Request
**Check logs for:**
```
[API] POST /api/Account/verify-otp - Status: 400
[API] Error: 400 - Invalid OTP Code
```
**Solutions:**
- OTP code is incorrect (copy from email)
- OTP is expired (timeout between signup and verification)
- Email not correct in system

## Testing Your Changes

### Step 1: Run with Verbose Logging
```bash
cd d:\Flutter\ Projects\Test_Ain_Graduation_Project
flutter clean
flutter pub get
flutter run -v
```

### Step 2: Complete the Signup Flow
1. Open app
2. Go to Sign Up page
3. Fill in all fields
4. Click Sign Up
5. Wait for OTP email (check console logs)
6. Copy OTP code from email
7. Enter OTP on verification page
8. Click Verify

### Step 3: Collect Logs
- Copy all logs with `[AUTH]`, `[API]`, `[EMAIL_VERIFY]` prefixes
- Note any errors or unusual values

### Step 4: Share Results
Include:
1. All logs from signup to verification attempt
2. The HTTP status code shown in `[API]` logs
3. Any error messages displayed in the app

## Expected Success Logs

```
[AUTH] Starting signup step one with email: test@example.com
[API] POST /api/Account/signup-stepOne
[API] POST /api/Account/signup-stepOne - Status: 200
[AUTH] Signup step one response received
[AUTH] Extracted signup token: YES (length: 185)
[AUTH] Saving signup token to local storage...
[AUTH] Signup token saved successfully
[AUTH] Verification - Token in storage: YES (length: 185)
✅ Navigation to email verification page

[EMAIL_VERIFY] Starting email verification for: test@example.com
[EMAIL_VERIFY] OTP Code: 123456
[AUTH] Retrieved signup token: EXISTS (length: 185)
[AUTH] Starting OTP verification with token length: 185
[API] POST /api/Account/verify-otp
[API] Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI...
[API] POST /api/Account/verify-otp - Status: 200
[AUTH] OTP verified successfully
[API] POST /api/Account/complete-signup
[API] Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI...
[API] POST /api/Account/complete-signup - Status: 200
[AUTH] Sign up completed. Received authToken: YES
[AUTH] Saving session with token length: 185
[AUTH] Session saved and signup token cleared
[EMAIL_VERIFY] Success!
✅ Navigation to ID Verification page
```

## Files to Monitor During Testing

1. **auth_repository_impl.dart** - Logs token save/retrieve
2. **api_client.dart** - Logs API calls and HTTP status codes
3. **email_verification_notifier.dart** - Logs verification steps
4. **app console** - Shows all print() statements

## Debugging if Still Failing

Create a temporary file to test token persistence:

```dart
// Add to splash_page.dart or main.dart initState
Future<void> _debugSignupFlow() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Clear old token
  await prefs.remove('auth_cached_signup_token_v1');
  
  // Save test token
  const testToken = 'test_token_12345';
  await prefs.setString('auth_cached_signup_token_v1', testToken);
  
  // Retrieve it
  final retrieved = prefs.getString('auth_cached_signup_token_v1');
  
  print('[DEBUG] Token save/retrieve test:');
  print('[DEBUG] Saved: $testToken');
  print('[DEBUG] Retrieved: $retrieved');
  print('[DEBUG] Match: ${testToken == retrieved}');
}
```

---

## Summary

✅ **Code is correctly structured**
⚠️ **Need to see actual error logs to identify the exact failure point**
🔍 **New logging will help pinpoint where the problem is**

**Next action:** Run your app with `flutter run -v`, complete the signup flow, and share the logs showing where it fails!
