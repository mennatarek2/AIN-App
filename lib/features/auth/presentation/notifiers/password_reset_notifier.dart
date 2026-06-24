import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../state/form_state_simple.dart';

class PasswordResetNotifier extends StateNotifier<FormState> {
  PasswordResetNotifier(this._repository) : super(const FormInitial());

  final AuthRepository _repository;
  String? _resetEmail;
  String? _resetAccessToken;

  Future<bool> sendPasswordResetEmail({required String email}) async {
    state = const FormLoading();
    _resetEmail = email.trim();
    _resetAccessToken = null;

    final result = await _repository.sendPasswordResetEmail(email: email);

    return result.fold(
      (failure) {
        state = FormError(failure);
        return false;
      },
      (_) {
        state = const FormSuccess();
        return true;
      },
    );
  }

  Future<bool> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = const FormLoading();

    final email = _resetEmail?.trim();
    final token = _resetAccessToken?.trim();
    if (email == null ||
        email.isEmpty ||
        token == null ||
        token.isEmpty) {
      state = const FormError(
        ServerFailure('Password reset session expired. Please start again.'),
      );
      return false;
    }

    final result = await _repository.resetPassword(
      email: email,
      token: token,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    return result.fold(
      (failure) {
        state = FormError(failure);
        return false;
      },
      (user) {
        _resetAccessToken = null;
        state = const FormSuccess();
        return true;
      },
    );
  }

  Future<bool> verifyResetCode({
    required String email,
    required String code,
  }) async {
    state = const FormLoading();
    _resetEmail = email.trim();

    final result = await _repository.verifyPasswordResetCode(
      email: email,
      code: code,
    );

    return result.fold(
      (failure) {
        state = FormError(failure);
        return false;
      },
      (accessToken) {
        _resetAccessToken = accessToken;
        state = const FormSuccess();
        return true;
      },
    );
  }

  Future<bool> resendForgotPasswordOtp() async {
    state = const FormLoading();

    final result = await _repository.resendForgotPasswordOtp();

    return result.fold(
      (failure) {
        state = FormError(failure);
        return false;
      },
      (_) {
        state = const FormSuccess();
        return true;
      },
    );
  }

  String? get resetEmail => _resetEmail;

  void reset() {
    state = const FormInitial();
  }
}

final passwordResetNotifierProvider =
    StateNotifierProvider<PasswordResetNotifier, FormState>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      return PasswordResetNotifier(repository);
    });
