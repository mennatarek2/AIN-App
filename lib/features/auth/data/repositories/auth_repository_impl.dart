import 'package:dartz/dartz.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/utils/username_utils.dart';
import '../data_sources/auth_remote_data_source.dart';
import '../data_sources/mock_auth_data_source.dart';
import '../data_sources/user_local_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final MockAuthDataSource mockDataSource;
  final UserLocalDataSource userLocalDataSource;

  AuthRepositoryImpl(
    this.remoteDataSource,
    this.mockDataSource,
    this.userLocalDataSource,
  );

  @override
  Future<Either<AuthFailure, User>> signUp({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String ssn,
  }) async {
    try {
      final normalizedEmail = email.trim();
      final userName = UsernameUtils.fromEmail(normalizedEmail);
      if (userName == null) {
        return Left(const InvalidEmailFailure());
      }

      print('[AUTH] Starting signup step one with email: $email');
      final session = await remoteDataSource.signUpStepOne(
        displayName: name,
        userName: userName,
        email: normalizedEmail,
        phoneNumber: phoneNumber,
        ssn: ssn,
        password: password,
        confirmPassword: password,
      );
      print('[AUTH] Signup step one response received');

      final signupToken = session.signupToken?.trim();
      print(
        '[AUTH] Extracted signup token: ${signupToken != null ? 'YES (length: ${signupToken.length})' : 'NO'}',
      );

      if (signupToken == null || signupToken.isEmpty) {
        print('[AUTH] ERROR: Sign-up token missing from response');
        print(
          '[AUTH] Response authToken: ${session.authToken != null ? 'YES' : 'NO'}',
        );
        return Left(
          const ServerFailure(
            'Sign-up token missing from signup-stepOne response',
          ),
        );
      }

      print('[AUTH] Saving signup token to local storage...');
      await userLocalDataSource.saveSignupToken(signupToken);
      print('[AUTH] Signup token saved successfully');

      // Verify token was saved
      final savedToken = await userLocalDataSource.getSignupToken();
      print(
        '[AUTH] Verification - Token in storage: ${savedToken != null ? 'YES (length: ${savedToken.length})' : 'NO'}',
      );

      final user =
          session.user ??
          UserModel(
            id: normalizedEmail,
            email: normalizedEmail,
            name: name,
            isVerified: false,
            phoneNumber: phoneNumber,
          );

      return Right(user);
    } catch (e) {
      print('[AUTH] ERROR in signUp: $e');
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<AuthFailure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await remoteDataSource.login(
        email: email,
        password: password,
      );

      final token = session.authToken;
      final user =
          session.user ??
          UserModel(
            id: email,
            email: email,
            name: email.split('@').first,
            isVerified: false,
          );

      if (token != null && token.trim().isNotEmpty) {
        await userLocalDataSource.saveSession(
          user: user,
          token: token,
          refreshToken: session.refreshToken,
        );
      }

      return Right(user);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await mockDataSource.sendPasswordResetEmail(email: email);
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await mockDataSource.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    try {
      await mockDataSource.verifyPasswordResetCode(email: email, code: code);
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      // Retrieve signup token
      final signupToken = await userLocalDataSource.getSignupToken();
      print(
        '[AUTH] Retrieved signup token: ${signupToken != null ? 'EXISTS' : 'NULL'} (length: ${signupToken?.length ?? 0})',
      );

      if (signupToken == null || signupToken.trim().isEmpty) {
        print('[AUTH] ERROR: Signup token is missing or empty');
        return Left(const InvalidTokenFailure());
      }

      print(
        '[AUTH] Starting OTP verification with token length: ${signupToken.length}',
      );
      await remoteDataSource.verifyOtp(otpCode: code, signupToken: signupToken);
      print('[AUTH] OTP verified successfully');

      return const Right(null);
    } catch (e) {
      print('[AUTH] ERROR in verifyEmail: $e');
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<AuthFailure, User>> completeSignUp({
    required String email,
    required String name,
  }) async {
    try {
      final signupToken = await userLocalDataSource.getSignupToken();
      print(
        '[AUTH] Complete signup: Retrieved signup token: ${signupToken != null ? 'EXISTS' : 'NULL'} (length: ${signupToken?.length ?? 0})',
      );

      if (signupToken == null || signupToken.trim().isEmpty) {
        print('[AUTH] Complete signup: ERROR - Signup token is missing');
        return Left(const InvalidTokenFailure());
      }

      print('[AUTH] Completing sign up...');
      final session = await remoteDataSource.completeSignUp(
        signupToken: signupToken,
      );
      print(
        '[AUTH] Sign up completed. Received authToken: ${session.authToken != null ? 'YES' : 'NO'}',
      );

      final fallbackUser = UserModel(
        id: email.trim().isNotEmpty ? email.trim() : signupToken,
        email: email.trim(),
        name: name.trim().isNotEmpty ? name.trim() : email.trim().split('@').first,
        isVerified: true,
      );
      final user = session.user ?? fallbackUser;

      final token = session.authToken;
      if (token != null && token.trim().isNotEmpty) {
        print('[AUTH] Saving session with token length: ${token.length}');
        await userLocalDataSource.saveSession(
          user: user,
          token: token,
          refreshToken: session.refreshToken,
        );
        await userLocalDataSource.clearSignupToken();
        print('[AUTH] Session saved and signup token cleared');
      } else {
        print('[AUTH] WARNING: No auth token received from complete signup');
      }

      return Right(user);
    } catch (e) {
      print('[AUTH] ERROR in completeSignUp: $e');
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> resendOtp() async {
    try {
      final signupToken = await userLocalDataSource.getSignupToken();
      print(
        '[AUTH] Resend OTP: Retrieved signup token: ${signupToken != null ? 'EXISTS' : 'NULL'}',
      );

      if (signupToken == null || signupToken.trim().isEmpty) {
        print('[AUTH] Resend OTP: ERROR - Signup token is missing');
        return Left(const InvalidTokenFailure());
      }

      print('[AUTH] Resend OTP: Calling remote data source...');
      await remoteDataSource.resendOtp(signupToken: signupToken);
      print('[AUTH] Resend OTP: Successfully sent');
      return const Right(null);
    } catch (e) {
      print('[AUTH] ERROR in resendOtp: $e');
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> uploadIdDocuments({
    required String frontImagePath,
    required String backImagePath,
    required String selfieImagePath,
  }) async {
    try {
      final signupToken = await userLocalDataSource.getSignupToken();
      if (signupToken == null || signupToken.trim().isEmpty) {
        return Left(const InvalidTokenFailure());
      }

      await remoteDataSource.uploadIdDocuments(
        signupToken: signupToken,
        frontImagePath: frontImagePath,
        backImagePath: backImagePath,
        selfieImagePath: selfieImagePath,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<AuthFailure, User>> getCurrentUser() async {
    try {
      final cachedUser = await userLocalDataSource.getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser.toEntity());
      }

      return Left(const InvalidTokenFailure());
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final token = await userLocalDataSource.getCachedToken();
      if (token == null || token.trim().isEmpty) {
        return Left(const InvalidTokenFailure());
      }

      await remoteDataSource.changePassword(
        authToken: token,
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> logout() async {
    try {
      final token = await userLocalDataSource.getCachedToken();
      final refreshToken = await userLocalDataSource.getCachedRefreshToken();
      if (token != null &&
          token.trim().isNotEmpty &&
          refreshToken != null &&
          refreshToken.trim().isNotEmpty) {
        await remoteDataSource.signOut(
          authToken: token,
          refreshToken: refreshToken,
        );
      }
      await userLocalDataSource.clearSession();
      return const Right(null);
    } catch (e) {
      await userLocalDataSource.clearSession();
      return Left(_handleException(e));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await userLocalDataSource.hasValidSession();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getAuthToken() async {
    try {
      return await userLocalDataSource.getCachedToken();
    } catch (e) {
      return null;
    }
  }

  AuthFailure _handleException(Object e) {
    final message = e is ApiException ? e.message : e.toString();

    if (message.contains('already exists')) {
      return const UserAlreadyExistsFailure();
    } else if (message.contains('Invalid email or password')) {
      return const InvalidCredentialsFailure();
    } else if (message.contains('Invalid email format')) {
      return const InvalidEmailFailure();
    } else if (message.contains('too weak')) {
      return const WeakPasswordFailure();
    } else if (message.contains('Invalid or expired token')) {
      return const InvalidTokenFailure();
    } else if (message.contains('Network') || message.contains('connection')) {
      return const NetworkFailure();
    } else {
      return ServerFailure(message);
    }
  }
}
