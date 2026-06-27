import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/data_sources/chatbot_remote_data_source.dart';
import '../../data/repositories/chatbot_repository_impl.dart';
import '../../domain/repositories/chatbot_repository.dart';

final chatbotRemoteDataSourceProvider = Provider<ChatbotRemoteDataSource>((
  ref,
) {
  final userLocal = ref.watch(userLocalDataSourceProvider);
  return ChatbotRemoteDataSource(
    ref.watch(apiClientProvider),
    readToken: userLocal.getCachedToken,
  );
});

final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  return ChatbotRepositoryImpl(ref.watch(chatbotRemoteDataSourceProvider));
});
