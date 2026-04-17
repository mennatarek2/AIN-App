import 'package:equatable/equatable.dart';

abstract class AuthFailure extends Equatable {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends AuthFailure {
  const ServerFailure(super.message);
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure() : super('Invalid email or password');
}

class UserAlreadyExistsFailure extends AuthFailure {
  const UserAlreadyExistsFailure() : super('User already exists');
}

class NetworkFailure extends AuthFailure {
  const NetworkFailure() : super('Network connection failed');
}

class InvalidTokenFailure extends AuthFailure {
  const InvalidTokenFailure() : super('Invalid or expired token');
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure() : super('Password is too weak');
}

class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure() : super('Invalid email format');
}
