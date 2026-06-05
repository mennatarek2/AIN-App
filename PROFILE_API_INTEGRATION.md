# Profile API Integration Guide

## Overview

Complete Profile API integration with automatic authentication, caching, error handling, and state management using Riverpod.

**Default values for new accounts:**
- Trust Points: 50
- Level: 1 (مستخدم جديد)

## Architecture

### Data Layer
- **ProfileRemoteDataSource**: API communication with retry logic
- **ProfileLocalDataSource**: Local caching using SharedPreferences
- **ProfileRepositoryImpl**: Combines remote & local data with offline support

### Domain Layer
- **ProfileRepository**: Abstract interface
- **ProfileModel**: Entity with points and level calculation
- **Use Cases**: 
  - `GetProfileUseCase`: Fetch profile
  - `UpdateProfileUseCase`: Update profile with multipart support

### Presentation Layer
- **ProfileNotifier**: Riverpod StateNotifier with AsyncValue states
- **Providers**: 
  - `profileAsyncProvider`: Full AsyncValue<UserProfile> state
  - `profileProvider`: Simple UserProfile? synchronous access
  - `profileLoadingProvider`: Loading state
  - `profileErrorProvider`: Error message
  - `updateProfileUseCaseProvider`: For mutations

## API Endpoints

### 1. GET /Profile/my-profile
Fetch user profile after login.

**Authorization:** Bearer token (required)
**Response:** User profile with trust points and level

**Example:**
```dart
final profile = await getProfileUseCase();
```

### 2. PUT /Profile/update-profile
Update profile information and/or photo.

**Authorization:** Bearer token (required)
**Content-Type:** multipart/form-data

**Fields:**
- `displayName` (string, optional): User's display name
- `phoneNumber` (string, optional): Phone number
- `profilePhoto` (file, optional): Image file (jpg/png)

**Example:**
```dart
await updateProfileUseCase(
  displayName: 'John Doe',
  phoneNumber: '+1234567890',
  profilePhotoPath: '/path/to/image.jpg',
);
```

## Usage Examples

### 1. Get Current Profile
```dart
final profile = ref.watch(profileProvider);
final isLoading = ref.watch(profileLoadingProvider);
final error = ref.watch(profileErrorProvider);

if (isLoading) {
  return CircularProgressIndicator();
}

if (error != null) {
  return Text('Error: $error');
}

if (profile != null) {
  return Column(
    children: [
      Text('Name: ${profile.name}'),
      Text('Points: ${profile.points}'),
      Text('Level: ${profile.level}'),
    ],
  );
}
```

### 2. Update Profile
```dart
final notifier = ref.read(profileAsyncProvider.notifier);

// Update name
await notifier.updateName('John Doe');

// Update phone
await notifier.updatePhone('+1234567890');

// Update with photo
await notifier.updateProfilePhoto('/path/to/photo.jpg');

// Update multiple fields
await notifier.updateProfileData(
  displayName: 'Jane Doe',
  phoneNumber: '+0987654321',
  profilePhotoPath: '/path/to/new/photo.jpg',
);
```

### 3. Manual Refresh
```dart
final notifier = ref.read(profileAsyncProvider.notifier);
await notifier.refresh();
```

### 4. Handle Points
```dart
final notifier = ref.read(profileAsyncProvider.notifier);

// Add points
notifier.addPoints(10);

// Subtract points
notifier.subtractPoints(5);

// Apply report outcome
notifier.applyReportOutcome(resolved: true); // +10 points
notifier.applyReportOutcome(resolved: false); // -10 points
```

## Features

### ✅ Authentication
- Automatic Bearer token attachment to requests
- Token validation and error handling
- 401 error handling for expired tokens

### ✅ Offline Support
- Automatic caching to SharedPreferences
- Offline reads from cache
- Automatic sync when online

### ✅ Error Handling
- Automatic retry logic (up to 2 attempts with backoff)
- Comprehensive error messages
- Connection error detection
- ProfileException with error codes

### ✅ Image Upload
- Multipart form data support
- File existence validation
- Automatic image path handling
- Progress indication support

### ✅ State Management
- AsyncValue for loading/error/success states
- Immediate UI updates (optimistic)
- Automatic revert on failure
- Type-safe Riverpod providers

### ✅ Auto-Initialization
- Profile auto-fetches on app start
- Loads from cache immediately
- Fetches latest from API in background
- Handles both online and offline scenarios

## Token Management

Tokens are handled automatically:

```dart
// Token is read from UserLocalDataSource
// Automatically attached to all profile requests
// Invalid/expired tokens trigger 401 error

// If token expires:
// 1. API returns 401
// 2. ProfileException thrown with code 401
// 3. App redirects to login (handle in UI)
```

## Error Scenarios

| Error | Code | Handling |
|-------|------|----------|
| Missing Token | 401 | Redirect to login |
| Network Error | 0 | Use cache if available |
| API Error | 5xx | Retry up to 2 times |
| Empty Response | 500 | Show error message |
| No Cache & Offline | 0 | Show offline message |

## Local Caching

Profile is cached automatically:

```dart
// Cache location: SharedPreferences
// Cache key: 'profile_cache'
// Cache format: JSON

// Automatic cache updates:
// - After successful API fetch
// - After successful profile update

// Cache clearing:
// - Manual: await localDataSource.clearProfile()
// - On logout: Clear in auth flow
```

## Testing

```dart
// Mock the repository
final mockRepository = MockProfileRepository();

// Test profile fetch
when(mockRepository.fetchMyProfile()).thenAnswer((_) async => null);

// Test profile update
when(mockRepository.updateProfile(...)).thenAnswer((_) async => null);

// Use in provider override
testWidgets('Profile display', (tester) async {
  await tester.pumpWidget(
    ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: YourWidget(),
    ),
  );
});
```

## Troubleshooting

### Profile not loading
1. Check token is valid and cached
2. Check internet connection
3. Check API endpoint is correct
4. Check API response format

### Image not uploading
1. Verify file exists at path
2. Check file permissions
3. Check file size (< 5MB recommended)
4. Verify supported format (jpg/png)

### Points not updating
1. Check profile is loaded
2. Ensure update succeeded (no errors)
3. Refresh profile to sync with server
4. Check local cache was updated

## Default Values

All new accounts receive:
- **Trust Points:** 50
- **Level:** 1 (مستخدم جديد - New User)

These values are:
- Set automatically on account creation
- Shown immediately after login
- Updated in local cache
- Displayed in profile UI

## Best Practices

1. **Always handle AsyncValue states**
   ```dart
   async.whenData((profile) => ShowProfile(profile))
   async.whenLoading(() => LoadingWidget())
   async.whenError((error, st) => ErrorWidget(error))
   ```

2. **Use profileProvider for simple access**
   ```dart
   final profile = ref.watch(profileProvider);
   // Returns null if loading/error
   ```

3. **Update UI optimistically**
   ```dart
   // Local state updates immediately
   // Network sync happens in background
   ```

4. **Handle errors gracefully**
   ```dart
   try {
     await notifier.updateName(name);
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Profile updated')),
     );
   } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Error: $e')),
     );
   }
   ```

## Migration Guide

If updating from old profile system:

1. Clear app cache and localStorage
2. Ensure token is properly stored by auth system
3. Update UI to use new providers
4. Test with production API
5. Verify caching works offline
