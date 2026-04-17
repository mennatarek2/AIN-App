import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ain_graduation_project/features/auth/data/data_sources/user_local_data_source.dart';
import 'package:ain_graduation_project/features/auth/data/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserLocalDataSource', () {
    late UserLocalDataSource dataSource;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      dataSource = UserLocalDataSource();
    });

    test('saves and reads cached session correctly', () async {
      const user = UserModel(
        id: 'u-1',
        email: 'user@example.com',
        name: 'User One',
        isVerified: true,
        phoneNumber: '+201000000000',
        profileImageUrl: 'https://example.com/avatar.png',
      );

      await dataSource.saveSession(user: user, token: 'token-123');

      final cachedUser = await dataSource.getCachedUser();
      final cachedToken = await dataSource.getCachedToken();

      expect(cachedUser, isNotNull);
      expect(cachedUser!.id, user.id);
      expect(cachedUser.email, user.email);
      expect(cachedUser.name, user.name);
      expect(cachedUser.profileImageUrl, user.profileImageUrl);
      expect(cachedToken, 'token-123');
      expect(await dataSource.hasValidSession(), isTrue);
    });

    test('clears cached session', () async {
      const user = UserModel(
        id: 'u-2',
        email: 'second@example.com',
        name: 'Second User',
        isVerified: false,
      );

      await dataSource.saveSession(user: user, token: 'token-clear');
      expect(await dataSource.hasValidSession(), isTrue);

      await dataSource.clearSession();

      expect(await dataSource.getCachedUser(), isNull);
      expect(await dataSource.getCachedToken(), isNull);
      expect(await dataSource.hasValidSession(), isFalse);
    });

    test('returns null for malformed cached user payload', () async {
      SharedPreferences.setMockInitialValues({
        'auth_cached_user_v1': 'not-a-json-map',
        'auth_cached_token_v1': 'token-x',
      });

      dataSource = UserLocalDataSource();

      expect(await dataSource.getCachedUser(), isNull);
      expect(await dataSource.getCachedToken(), 'token-x');
      expect(await dataSource.hasValidSession(), isFalse);
    });
  });
}
