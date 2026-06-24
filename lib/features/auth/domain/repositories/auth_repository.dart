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
    required String ssn,
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

  /// Reset password with token from OTP verification
  Future<Either<AuthFailure, User>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
    required String confirmPassword,
  });

  /// Verify password reset OTP and return the reset access token
  Future<Either<AuthFailure, String>> verifyPasswordResetCode({
    required String email,
    required String code,
  });

  /// Resend forgot-password OTP
  Future<Either<AuthFailure, void>> resendForgotPasswordOtp();

  /// Verify email with code
  Future<Either<AuthFailure, void>> verifyEmail({
    required String email,
    required String code,
  });

  /// Complete sign up after all verification steps
  Future<Either<AuthFailure, User>> completeSignUp({
    required String email,
    required String name,
  });

  /// Resend OTP for sign-up verification
  Future<Either<AuthFailure, void>> resendOtp();

  /// Upload ID verification documents
  Future<Either<AuthFailure, void>> uploadIdDocuments({
    required String frontImagePath,
    required String backImagePath,
    required String selfieImagePath,
  });

  /// Get current authenticated user
  Future<Either<AuthFailure, User>> getCurrentUser();

  /// Change password for the authenticated user
  Future<Either<AuthFailure, void>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  });

  /// Logout
  Future<Either<AuthFailure, void>> logout();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Get stored auth token
  Future<String?> getAuthToken();
}
