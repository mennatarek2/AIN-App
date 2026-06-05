# Quick Start Guide - Profile API Integration

## 1. Automatic Profile Loading (On App Start)

Profile automatically loads after login:

```dart
// In main.dart or your root widget
void main() async {
  // ... initialization ...
  
  // Profile will auto-fetch after login:
  // 1. Loads from cache immediately (if exists)
  // 2. Fetches latest from API in background
  // 3. Saves to cache automatically
}
```

## 2. Display User Profile

```dart
class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch profile with all states
    final asyncProfile = ref.watch(profileAsyncProvider);
    
    return asyncProfile.when(
      // Loading state
      loading: () => const Center(child: CircularProgressIndicator()),
      
      // Error state
      error: (error, stackTrace) => Center(
        child: Column(
          children: [
            Text('Error: $error'),
            ElevatedButton(
              onPressed: () {
                ref.read(profileAsyncProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      
      // Success state
      data: (profile) => Column(
        children: [
          Text('Name: ${profile.name}'),
          Text('Email: ${profile.email}'),
          Text('Phone: ${profile.phone}'),
          Text('Points: ${profile.points}'),
          Text('Level: ${profile.level}'),
          Text('Verified: ${profile.isVerified ? "✓" : "✗"}'),
        ],
      ),
    );
  }
}
```

## 3. Update Profile Information

```dart
class EditProfileScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  
  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    nameController = TextEditingController(text: profile?.name ?? '');
    phoneController = TextEditingController(text: profile?.phone ?? '');
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        TextField(
          controller: phoneController,
          decoration: const InputDecoration(labelText: 'Phone'),
        ),
        ElevatedButton(
          onPressed: () => _updateProfile(),
          child: const Text('Save'),
        ),
      ],
    );
  }
  
  Future<void> _updateProfile() async {
    try {
      final notifier = ref.read(profileAsyncProvider.notifier);
      
      await notifier.updateProfileData(
        displayName: nameController.text,
        phoneNumber: phoneController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  
  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
```

## 4. Upload Profile Photo

```dart
class UpdatePhotoScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _pickAndUpdatePhoto(context, ref),
      child: const Text('Change Profile Photo'),
    );
  }
  
  Future<void> _pickAndUpdatePhoto(BuildContext context, WidgetRef ref) async {
    // Assuming you're using image_picker
    // final ImagePicker picker = ImagePicker();
    // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    // For this example:
    final String? photoPath = '/path/to/selected/image.jpg';
    
    if (photoPath == null) return;
    
    try {
      final notifier = ref.read(profileAsyncProvider.notifier);
      await notifier.updateProfilePhoto(photoPath);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
```

## 5. Refresh Profile Manually

```dart
ElevatedButton(
  onPressed: () {
    ref.read(profileAsyncProvider.notifier).refresh();
  },
  child: const Text('Refresh Profile'),
)
```

## 6. Access Individual Fields

```dart
class ProfileWidgets extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final isLoading = ref.watch(profileLoadingProvider);
    final errorMsg = ref.watch(profileErrorProvider);
    
    if (isLoading) return const CircularProgressIndicator();
    if (errorMsg != null) return Text('Error: $errorMsg');
    if (profile == null) return const Text('No profile');
    
    return Column(
      children: [
        Text('Name: ${profile.name}'),
        Text('Email: ${profile.email}'),
        Text('Level: ${profile.level}'),
        Text('Points: ${profile.points}'),
        Text('Points to next level: ${profile.pointsToNextLevel}'),
      ],
    );
  }
}
```

## 7. Handle Points Changes

```dart
class ReportScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        final notifier = ref.read(profileAsyncProvider.notifier);
        // Report resolved: +10 points
        notifier.applyReportOutcome(resolved: true);
      },
      child: const Text('Mark as Resolved'),
    );
  }
}
```

## 8. Response Scenarios

### Success Response
```json
{
  "id": "user-123",
  "displayName": "John Doe",
  "email": "john@example.com",
  "phoneNumber": "+1234567890",
  "userName": "john_doe",
  "isVerified": true,
  "points": 50
}
```

### New Account (Default Values)
```json
{
  "id": "new-user-456",
  "displayName": "Jane Smith",
  "email": "jane@example.com",
  "phoneNumber": "",
  "userName": "jane_smith",
  "isVerified": false,
  "points": 50
}
```

## 9. Common Patterns

### Pattern: Show "Loading" then "Success"
```dart
ref.watch(profileAsyncProvider).when(
  loading: () => LoadingWidget(),
  data: (profile) => ProfileWidget(profile),
  error: (error, st) => ErrorWidget(error),
)
```

### Pattern: Simple Profile Access
```dart
final profile = ref.watch(profileProvider);
if (profile != null) {
  // Use profile...
}
```

### Pattern: Update with Feedback
```dart
try {
  await notifier.updateName(newName);
  showSnackBar('Updated!');
} catch (e) {
  showSnackBar('Error: $e');
}
```

## Default Values for New Accounts

When a new user signs up:
- **Trust Points:** 50
- **Level:** 1 (مستخدم جديد)

These are automatically set by the backend and returned in the profile response.

## Token Handling

Tokens are automatically managed:
1. Token stored after login
2. Automatically attached to all requests
3. If expired, API returns 401
4. Handle by redirecting to login

```dart
// Token is managed by auth system
// No manual token handling needed!
```

## Offline Support

Profile works offline:
```dart
// If offline and no cache: Shows error
// If offline and cache exists: Uses cached profile
// Auto syncs when online
```

## Complete Example App

```dart
void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProfilePage(),
    );
  }
}

class ProfilePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(profileAsyncProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: asyncProfile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('Error: $error')),
        data: (profile) => ListView(
          children: [
            ListTile(title: Text('Name: ${profile.name}')),
            ListTile(title: Text('Email: ${profile.email}')),
            ListTile(title: Text('Points: ${profile.points}')),
            ListTile(title: Text('Level: ${profile.level}')),
            ElevatedButton(
              onPressed: () => ref.read(profileAsyncProvider.notifier).refresh(),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Profile not loading | Check token is valid and stored |
| Image upload fails | Verify file path exists and format is jpg/png |
| Offline error | Ensure app has read/write to cache |
| Token expired | App redirects to login (handle in auth) |
| Points not syncing | Call refresh() to sync with server |
