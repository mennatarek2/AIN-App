import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/auth_token_utils.dart';
import '../models/user_model.dart';

class AuthSession {
  const AuthSession({
    this.user,
    this.authToken,
    this.signupToken,
    this.refreshToken,
  });

  final UserModel? user;
  final String? authToken;
  final String? signupToken;
  final String? refreshToken;
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

  Future<void> signOut({
    required String authToken,
    required String refreshToken,
  }) async {
    await _client.postJson(
      ApiEndpoints.signOut,
      token: authToken,
      body: {'refreshToken': refreshToken},
    );
  }

  Future<void> changePassword({
    required String authToken,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _client.postJson(
      ApiEndpoints.changePassword,
      token: authToken,
      body: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  Future<String?> sendForgotPasswordOtp({required String email}) async {
    final response = await _client.postJson(
      ApiEndpoints.resendForgotPasswordOtp,
      body: {'email': email.trim()},
    );
    _assertAuthSuccess(response);
    return _extractAuthToken(response);
  }

  Future<void> resendForgotPasswordOtp({
    String? forgotPasswordToken,
    String? email,
  }) async {
    await _client.postJson(
      ApiEndpoints.resendForgotPasswordOtp,
      token: forgotPasswordToken,
      body: email != null && email.trim().isNotEmpty
          ? {'email': email.trim()}
          : null,
    );
  }

  Future<String> verifyForgotPasswordOtp({
    required String otpCode,
    String? forgotPasswordToken,
    String? email,
  }) async {
    final response = await _client.postJson(
      ApiEndpoints.verifyForgotPasswordOtp,
      token: forgotPasswordToken,
      body: {
        'otpCode': otpCode.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      },
    );
    _assertAuthSuccess(response);

    final token = _extractAuthToken(response);
    if (token == null || token.isEmpty) {
      throw ApiException(
        'Password reset verification succeeded but no access token was returned',
        statusCode: 500,
      );
    }
    return token;
  }

  Future<AuthSession> resetPassword({
    required String email,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _client.postJson(
      ApiEndpoints.resetPassword,
      body: {
        'email': email.trim(),
        'token': token.trim(),
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
    return _parseSession(response);
  }

  AuthSession _parseSession(dynamic payload) {
    _assertAuthSuccess(payload);

    final authToken = _extractAuthToken(payload);
    final refreshToken = _extractRefreshToken(payload);
    final signupToken = _findToken(payload, [
      'signupToken',
      'registrationToken',
    ]);
    final userMap = _findUserMap(payload);

    return AuthSession(
      authToken: authToken,
      refreshToken: refreshToken,
      signupToken: signupToken,
      user: userMap == null ? null : UserModel.fromApiJson(userMap),
    );
  }

  void _assertAuthSuccess(dynamic payload) {
    if (payload is! Map) return;

    final isSuccess = payload['isSuccess'] ?? payload['IsSuccess'];
    if (isSuccess == false) {
      final message =
          payload['message'] ??
          payload['Message'] ??
          payload['error'] ??
          payload['Error'] ??
          'Authentication failed';
      throw ApiException(message.toString(), statusCode: 401);
    }
  }

  String? _extractAuthToken(dynamic payload) {
    if (payload is Map) {
      final user = payload['user'] ?? payload['User'];
      if (user is Map) {
        final fromUser = _findToken(user, [
          'token',
          'accessToken',
          'authToken',
        ]);
        if (fromUser != null) return fromUser;
      }
    }

    return _findToken(payload, ['accessToken', 'token', 'authToken']);
  }

  String? _extractRefreshToken(dynamic payload) {
    if (payload is Map) {
      final user = payload['user'] ?? payload['User'];
      if (user is Map) {
        final fromUser = _findToken(user, ['refreshToken', 'refresh_token']);
        if (fromUser != null) return fromUser;
      }
    }

    return _findToken(payload, ['refreshToken', 'refresh_token']);
  }

  Map<String, dynamic>? _findUserMap(dynamic payload) {
    if (payload == null) return null;
    if (payload is Map<String, dynamic>) {
      final direct =
          payload['user'] ??
          payload['User'] ??
          payload['profile'] ??
          payload['Profile'] ??
          payload['data'] ??
          payload['Data'] ??
          payload['result'] ??
          payload['Result'];
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
      final normalizedKeys = keys.map((key) => key.toLowerCase()).toSet();
      for (final entry in payload.entries) {
        if (!normalizedKeys.contains(entry.key.toString().toLowerCase())) {
          continue;
        }
        final text = entry.value?.toString().trim();
        if (text != null && text.isNotEmpty) {
          return AuthTokenUtils.normalize(text) ?? text;
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
