import 'package:ain_graduation_project/features/auth/presentation/providers/auth_provider.dart';
import 'package:ain_graduation_project/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:ain_graduation_project/features/profile/presentation/pages/profile_page.dart';
import 'package:ain_graduation_project/features/profile/presentation/providers/profile_provider.dart';
import 'package:ain_graduation_project/features/profile/domain/profile_model.dart';
import 'package:ain_graduation_project/features/profile/domain/repositories/profile_repository.dart';
import 'package:ain_graduation_project/features/profile/domain/use_cases/use_cases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopProfileRepository implements ProfileRepository {
  @override
  Future<void> fetchMyProfile() async {}

  @override
  Future<ProfileModel?> getCachedProfile() async => null;

  @override
  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? profilePhotoPath,
  }) async {}

  @override
  Stream<ProfileModel?> watchProfile() async* {}

  @override
  Future<void> syncProfile() async {}
}

class _NoopGetProfileUseCase implements GetProfileUseCase {
  @override
  Future<void> call() async {}
  @override
  Future<ProfileModel?> getCached() async => null;
}

class _NoopUpdateProfileUseCase implements UpdateProfileUseCase {
  @override
  Future<void> call({
    String? displayName,
    String? phoneNumber,
    String? profilePhotoPath,
  }) async {}
}

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(AsyncValue<UserProfile> initial)
    : super(
        repository: _NoopProfileRepository(),
        getProfileUseCase: _NoopGetProfileUseCase(),
        updateProfileUseCase: _NoopUpdateProfileUseCase(),
      ) {
    state = initial;
  }

  @override
  Future<void> refresh() async {}
}

UserProfile _stubProfile() {
  return const UserProfile(
    id: 'u1',
    name: 'Test User',
    email: 'test@example.com',
    phone: '+201000000000',
    username: 'test_user',
    isVerified: true,
    points: 120,
  );
}

Widget _wrapWithScope({
  required Widget child,
  required AsyncValue<UserProfile> state,
}) {
  return ProviderScope(
    overrides: [
      profileAsyncProvider.overrideWith((ref) => _FakeProfileNotifier(state)),
      currentUserProvider.overrideWith((ref) => null),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('ProfilePage shows loading banner in loading state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithScope(
        child: const ProfilePage(),
        state: const AsyncValue<UserProfile>.loading(),
      ),
    );

    expect(
      find.byKey(const ValueKey('profile_state_loading_banner')),
      findsOneWidget,
    );
    expect(find.text('تعديل الملف الشخصي'), findsOneWidget);
  });

  testWidgets('ProfilePage shows error banner in error state', (tester) async {
    await tester.pumpWidget(
      _wrapWithScope(
        child: const ProfilePage(),
        state: AsyncValue<UserProfile>.error(
          'Failed to fetch',
          StackTrace.empty,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('profile_state_error_banner')),
      findsOneWidget,
    );
    expect(find.textContaining('حدث خطأ'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('EditProfilePage shows loading banner in loading state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithScope(
        child: const EditProfilePage(),
        state: const AsyncValue<UserProfile>.loading(),
      ),
    );

    expect(
      find.byKey(const ValueKey('profile_state_loading_banner')),
      findsOneWidget,
    );
    expect(find.text('حفظ التعديلات'), findsOneWidget);
  });

  testWidgets('EditProfilePage shows error banner in error state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithScope(
        child: const EditProfilePage(),
        state: AsyncValue<UserProfile>.error(
          'Failed to update',
          StackTrace.empty,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('profile_state_error_banner')),
      findsOneWidget,
    );
    expect(find.textContaining('حدث خطأ'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('EditProfilePage keeps save button disabled when loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithScope(
        child: const EditProfilePage(),
        state: const AsyncValue<UserProfile>.loading(),
      ),
    );

    final textButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'حفظ التعديلات'),
    );
    expect(textButton.onPressed, isNull);
  });

  testWidgets('EditProfilePage enables save button when data is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithScope(
        child: const EditProfilePage(),
        state: AsyncValue<UserProfile>.data(_stubProfile()),
      ),
    );

    final textButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'حفظ التعديلات'),
    );
    expect(textButton.onPressed, isNotNull);
  });
}
