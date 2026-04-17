import 'package:dartz/dartz.dart';

import '../entities/auth_failure.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  /// Sign Up with email and password
  Future<Either<AuthFailure, User>> signUp({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  });

  /// Login with email and password
  Future<Either<AuthFailure, User>> login({
    required String email,
    required String password,
  });

  /// Send password reset email
  Future<Either<AuthFailure, void>> sendPasswordResetEmail({
    required String email,
  });

  /// Reset password with token
  Future<Either<AuthFailure, void>> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Verify password reset token before allowing new password entry
  Future<Either<AuthFailure, void>> verifyPasswordResetCode({
    required String email,
    required String code,
  });

  /// Verify email with code
  Future<Either<AuthFailure, void>> verifyEmail({
    required String email,
    required String code,
  });

  /// Upload ID verification documents
  Future<Either<AuthFailure, void>> uploadIdDocuments({
    required String frontImagePath,
    required String backImagePath,
    required String selfieImagePath,
  });

  /// Get current authenticated user
  Future<Either<AuthFailure, User>> getCurrentUser();

  /// Logout
  Future<Either<AuthFailure, void>> logout();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Get stored auth token
  Future<String?> getAuthToken();
}
