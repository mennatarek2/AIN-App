import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../state/form_state_simple.dart';

class EmailVerificationNotifier extends StateNotifier<FormState> {
  final AuthRepository _repository;

  EmailVerificationNotifier(this._repository) : super(const FormInitial());

  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    state = const FormLoading();

    final result = await _repository.verifyEmail(email: email, code: code);

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

  void reset() {
    state = const FormInitial();
  }
}

final emailVerificationNotifierProvider =
    StateNotifierProvider<EmailVerificationNotifier, FormState>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      return EmailVerificationNotifier(repository);
    });
