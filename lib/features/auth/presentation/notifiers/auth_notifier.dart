import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import '../state/auth_state_simple.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthInitial()) {
    _checkAuthStatus();
  }

  /// Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    final isAuthenticated = await _repository.isAuthenticated();
    if (isAuthenticated) {
      final result = await _repository.getCurrentUser();
      result.fold(
        (failure) => state = const AuthUnauthenticated(),
        (user) => state = AuthAuthenticated(user),
      );
    } else {
      state = const AuthUnauthenticated();
    }
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String ssn,
  }) async {
    state = const AuthLoading();

    final result = await _repository.signUp(
      email: email,
      password: password,
      name: name,
      phoneNumber: phoneNumber,
      ssn: ssn,
    );

    return result.fold(
      (failure) {
        state = AuthError(failure);
        return false;
      },
      (_) {
        // Registration is in progress — no auth session yet.
        state = const AuthUnauthenticated();
        return true;
      },
    );
  }

  /// Login with email and password
  Future<bool> login({required String email, required String password}) async {
    state = const AuthLoading();

    final result = await _repository.login(email: email, password: password);

    return result.fold(
      (failure) {
        state = AuthError(failure);
        return false;
      },
      (user) {
        state = AuthAuthenticated(user);
        return true;
      },
    );
  }

  /// Complete sign up after document verification
  Future<bool> completeSignUp() async {
    final currentUser = state is AuthAuthenticated
        ? (state as AuthAuthenticated).user
        : null;

    state = const AuthLoading();

    final result = await _repository.completeSignUp(
      email: currentUser?.email ?? '',
      name: currentUser?.name ?? '',
    );

    return result.fold(
      (failure) {
        state = AuthError(failure);
        return false;
      },
      (user) {
        state = AuthAuthenticated(user);
        return true;
      },
    );
  }

  /// Logout
  Future<void> logout() async {
    await _repository.logout();
    state = const AuthUnauthenticated();
  }

  /// Reload auth state from persisted session (e.g. after password reset).
  Future<void> refreshSession() async {
    await _checkAuthStatus();
  }

  /// Clear error state
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}
