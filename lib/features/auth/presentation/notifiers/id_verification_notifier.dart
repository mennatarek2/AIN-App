import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../state/form_state_simple.dart';

class IdVerificationNotifier extends StateNotifier<FormState> {
  final AuthRepository _repository;

  IdVerificationNotifier(this._repository) : super(const FormInitial());

  Future<bool> uploadIdDocuments({
    required String frontImagePath,
    required String backImagePath,
    required String selfieImagePath,
  }) async {
    state = const FormLoading();

    final result = await _repository.uploadIdDocuments(
      frontImagePath: frontImagePath,
      backImagePath: backImagePath,
      selfieImagePath: selfieImagePath,
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

  void reset() {
    state = const FormInitial();
  }
}

final idVerificationNotifierProvider =
    StateNotifierProvider<IdVerificationNotifier, FormState>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      return IdVerificationNotifier(repository);
    });
