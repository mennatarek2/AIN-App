import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_failure.dart';

abstract class FormState extends Equatable {
  const FormState();

  @override
  List<Object?> get props => [];
}

class FormInitial extends FormState {
  const FormInitial();
}

class FormLoading extends FormState {
  const FormLoading();
}

class FormSuccess extends FormState {
  const FormSuccess();
}

class FormError extends FormState {
  final AuthFailure failure;

  const FormError(this.failure);

  @override
  List<Object?> get props => [failure];
}
