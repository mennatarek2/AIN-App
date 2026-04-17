import 'package:dartz/dartz.dart';

import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/mock_auth_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final MockAuthDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<Either<AuthFailure, User>> signUp({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    try {
      final result = await dataSource.signUp(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
      );
      final user = UserModel.fromJson(result['user'] as Map<String, dynamic>);
      return Right(user);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<AuthFailure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await dataSource.login(email: email, password: password);
      final user = UserModel.fromJson(result['user'] as Map<String, dynamic>);
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
      await dataSource.sendPasswordResetEmail(email: email);
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
      await dataSource.resetPassword(token: token, newPassword: newPassword);
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
      await dataSource.verifyPasswordResetCode(email: email, code: code);
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
      await dataSource.verifyEmail(email: email, code: code);
      return const Right(null);
    } catch (e) {
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
      await dataSource.uploadIdDocuments(
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
      final userJson = await dataSource.getCurrentUser();
      final user = UserModel.fromJson(userJson);
      return Right(user);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> logout() async {
    try {
      await dataSource.logout();
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await dataSource.isAuthenticated();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getAuthToken() async {
    try {
      return await dataSource.getAuthToken();
    } catch (e) {
      return null;
    }
  }

  AuthFailure _handleException(Object e) {
    final message = e.toString();

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
