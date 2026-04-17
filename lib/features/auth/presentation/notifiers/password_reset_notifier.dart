import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../state/form_state_simple.dart';

class PasswordResetNotifier extends StateNotifier<FormState> {
  final AuthRepository _repository;
  String? _resetEmail;

  PasswordResetNotifier(this._repository) : super(const FormInitial());

  Future<bool> sendPasswordResetEmail({required String email}) async {
    state = const FormLoading();
    _resetEmail = email;

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
    required String token,
    required String newPassword,
  }) async {
    state = const FormLoading();

    final result = await _repository.resetPassword(
      token: token,
      newPassword: newPassword,
    );

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

  Future<bool> verifyResetCode({
    required String email,
    required String code,
  }) async {
    state = const FormLoading();

    final result = await _repository.verifyPasswordResetCode(
      email: email,
      code: code,
    );

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
