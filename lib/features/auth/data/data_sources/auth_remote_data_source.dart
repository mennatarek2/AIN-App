import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

class AuthSession {
  const AuthSession({this.user, this.authToken, this.signupToken});

  final UserModel? user;
  final String? authToken;
  final String? signupToken;
}

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final ApiClient _client;

  Future<AuthSession> signUpStepOne({
    required String displayName,
    required String userName,
    required String email,
    required String phoneNumber,
    required String ssn,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _client.postJson(
      ApiEndpoints.signUpStepOne,
      body: {
        'displayName': displayName,
        'userName': userName,
        'email': email,
        'phoneNumber': phoneNumber,
        'ssn': ssn,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );
    final session = _parseSession(response);
    final signupToken = session.signupToken ?? session.authToken;

    return AuthSession(
      user: session.user,
      authToken: session.authToken,
      signupToken: signupToken,
    );
  }

  Future<void> verifyOtp({
    required String otpCode,
    required String signupToken,
  }) async {
    await _client.postJson(
      ApiEndpoints.verifyOtp,
      token: signupToken,
      body: {'otpCode': otpCode},
    );
  }

  Future<void> resendOtp({required String signupToken}) async {
    await _client.postJson(ApiEndpoints.resendOtp, token: signupToken);
  }

  Future<AuthSession> completeSignUp({required String signupToken}) async {
    final response = await _client.postJson(
      ApiEndpoints.completeSignUp,
      token: signupToken,
    );
    return _parseSession(response);
  }

  Future<void> uploadIdDocuments({
    required String signupToken,
    required String frontImagePath,
    required String backImagePath,
    required String selfieImagePath,
  }) async {
    // Upload ID card front & back using the API's expected field names
    await _client.postMultipart(
      ApiEndpoints.uploadIdCard,
      token: signupToken,
      filePaths: {'IDCardFront': frontImagePath, 'IDCardBack': backImagePath},
    );

    // Upload profile/selfie using the API's expected field name
    await _client.postMultipart(
      ApiEndpoints.uploadProfilePhoto,
      token: signupToken,
      filePaths: {'ProfilePhoto': selfieImagePath},
    );
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.postJson(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
    );
    return _parseSession(response);
  }

  Future<void> signOut({required String authToken}) async {
    await _client.postJson(ApiEndpoints.signOut, token: authToken);
  }

  AuthSession _parseSession(dynamic payload) {
    final authToken = _findToken(payload, [
      'token',
      'authToken',
      'accessToken',
    ]);
    final signupToken = _findToken(payload, [
      'signupToken',
      'registrationToken',
    ]);
    final userMap = _findUserMap(payload);

    return AuthSession(
      authToken: authToken,
      signupToken: signupToken,
      user: userMap == null ? null : UserModel.fromApiJson(userMap),
    );
  }

  Map<String, dynamic>? _findUserMap(dynamic payload) {
    if (payload == null) return null;
    if (payload is Map<String, dynamic>) {
      final direct =
          payload['user'] ??
          payload['profile'] ??
          payload['data'] ??
          payload['result'];
      if (direct is Map) {
        return Map<String, dynamic>.from(direct);
      }

      for (final value in payload.values) {
        final nested = _findUserMap(value);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  String? _findToken(dynamic payload, List<String> keys) {
    if (payload == null) return null;
    if (payload is Map) {
      for (final key in keys) {
        final value = payload[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      for (final value in payload.values) {
        final nested = _findToken(value, keys);
        if (nested != null) return nested;
      }
    }
    return null;
  }
}
