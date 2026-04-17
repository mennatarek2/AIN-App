import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_sources/mock_auth_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../notifiers/auth_notifier.dart';
import '../state/auth_state_simple.dart';

// Data Source Provider
final mockAuthDataSourceProvider = Provider<MockAuthDataSource>((ref) {
  return MockAuthDataSource();
});

// Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(mockAuthDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
});

// Auth State Notifier Provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

// Current User Provider (derived from auth state)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});

// Is Authenticated Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is AuthAuthenticated;
});
