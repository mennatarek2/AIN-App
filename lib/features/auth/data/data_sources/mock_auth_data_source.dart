import 'dart:math';

import '../models/user_model.dart';

/// Mock authentication data source that simulates API calls
/// This will be replaced with real API implementation later
class MockAuthDataSource {
  // Simulated database
  final Map<String, Map<String, dynamic>> _users = {};
  final Map<String, String> _tokens = {}; // email -> token
  final Map<String, String> _resetTokens = {}; // email -> reset token
  final Map<String, String> _verificationCodes = {}; // email -> code

  String? _currentUserEmail;

  /// Simulate network delay (1-2 seconds)
  Future<void> _delay([int minMs = 1000, int maxMs = 2000]) async {
    final random = Random();
    final delay = minMs + random.nextInt(maxMs - minMs);
    await Future.delayed(Duration(milliseconds: delay));
  }

  /// Generate random token
  String _generateToken() {
    final random = Random();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      64,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Generate 4-digit verification code
  String _generateVerificationCode() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  String _normalizeDigits(String input) {
    const arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const easternArabicIndic = [
      '۰',
      '۱',
      '۲',
      '۳',
      '۴',
      '۵',
      '۶',
      '۷',
      '۸',
      '۹',
    ];

    var normalized = input;
    for (var i = 0; i < 10; i++) {
      normalized = normalized.replaceAll(arabicIndic[i], i.toString());
      normalized = normalized.replaceAll(easternArabicIndic[i], i.toString());
    }
    return normalized.trim();
  }

  /// Sign up a new user
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    await _delay();

    // Check if user already exists
    if (_users.containsKey(email)) {
      throw Exception('User already exists');
    }

    // Validate email format
    if (!email.contains('@')) {
      throw Exception('Invalid email format');
    }

    // Validate password strength (min 6 characters)
    if (password.length < 6) {
      throw Exception('Password is too weak');
    }

    // Create user
    final userId = 'user_${_users.length + 1}';
    final user = UserModel(
      id: userId,
      email: email,
      name: name,
      isVerified: false,
      phoneNumber: phoneNumber,
      profileImageUrl: null,
    );

    _users[email] = {'user': user.toJson(), 'password': password};

    // Generate verification code
    final code = _generateVerificationCode();
    _verificationCodes[email] = code;
    print('\n📧 ======================================');
    print('📧 EMAIL VERIFICATION CODE: $code');
    print('📧 For: $email');
    print('📧 ======================================\n');

    // Generate token
    final token = _generateToken();
    _tokens[email] = token;
    _currentUserEmail = email;

    return {'user': user.toJson(), 'token': token};
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await _delay();

    // Check if user exists
    if (!_users.containsKey(email)) {
      throw Exception('Invalid email or password');
    }

    // Check password
    final storedPassword = _users[email]!['password'] as String;
    if (storedPassword != password) {
      throw Exception('Invalid email or password');
    }

    // Get user
    final userJson = _users[email]!['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);

    // Generate new token
    final token = _generateToken();
    _tokens[email] = token;
    _currentUserEmail = email;

    return {'user': user.toJson(), 'token': token};
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _delay();

    if (!_users.containsKey(email)) {
      // Don't reveal if email exists for security
      return;
    }

    final resetToken = _generateVerificationCode();
    _resetTokens[email] = resetToken;
    print('\n🔑 ======================================');
    print('🔑 PASSWORD RESET CODE: $resetToken');
    print('🔑 For: $email');
    print('🔑 Enter this code on the verification screen');
    print('🔑 ======================================\n');
  }

  /// Reset password with token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _delay();

    final normalizedToken = _normalizeDigits(token);

    final match = _resetTokens.entries.firstWhere(
      (entry) => entry.value == normalizedToken,
      orElse: () => const MapEntry('', ''),
    );

    if (match.key.isEmpty) {
      throw Exception('Invalid or expired token');
    }

    final email = match.key;

    if (newPassword.length < 6) {
      throw Exception('Password is too weak');
    }

    _users[email]!['password'] = newPassword;
    _resetTokens.remove(email);
  }

  /// Verify password reset code for a specific email
  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    await _delay();

    final normalizedCode = _normalizeDigits(code);
    final expectedCode = _resetTokens[email];

    if (expectedCode == null || expectedCode != normalizedCode) {
      throw Exception('Invalid or expired token');
    }
  }

  /// Verify email with code
  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    await _delay();

    if (!_verificationCodes.containsKey(email) ||
        _verificationCodes[email] != code) {
      throw Exception('Invalid verification code');
    }

    // Update user verification status
    final userJson = _users[email]!['user'] as Map<String, dynamic>;
    userJson['is_verified'] = true;
    _verificationCodes.remove(email);
  }

  /// Upload ID documents
  Future<void> uploadIdDocuments({
    required String frontImagePath,
    required String backImagePath,
    required String selfieImagePath,
  }) async {
    await _delay(1500, 2000);

    if (_currentUserEmail == null) {
      throw Exception('User not authenticated');
    }

    // In real implementation, would upload to server
    // For now, just simulate success
    print('📄 ID documents uploaded successfully');
    print('  Front: $frontImagePath');
    print('  Back: $backImagePath');
    print('  Selfie: $selfieImagePath');
  }

  /// Get current user
  Future<Map<String, dynamic>> getCurrentUser() async {
    await _delay();

    if (_currentUserEmail == null) {
      throw Exception('User not authenticated');
    }

    final userJson = _users[_currentUserEmail]!['user'] as Map<String, dynamic>;
    return userJson;
  }

  /// Logout
  Future<void> logout() async {
    await _delay();
    _tokens.remove(_currentUserEmail);
    _currentUserEmail = null;
  }

  /// Check if authenticated
  Future<bool> isAuthenticated() async {
    await _delay();
    return _currentUserEmail != null && _tokens.containsKey(_currentUserEmail);
  }

  /// Get auth token
  Future<String?> getAuthToken() async {
    await _delay();
    return _currentUserEmail != null ? _tokens[_currentUserEmail] : null;
  }
}
