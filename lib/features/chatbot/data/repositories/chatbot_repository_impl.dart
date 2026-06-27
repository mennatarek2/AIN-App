import '../../domain/repositories/chatbot_repository.dart';
import '../data_sources/chatbot_remote_data_source.dart';
import '../models/chat_response_model.dart';

class ChatbotRepositoryImpl implements ChatbotRepository {
  ChatbotRepositoryImpl(this._remoteDataSource);

  final ChatbotRemoteDataSource _remoteDataSource;

  @override
  Future<ChatResponseModel> sendMessage({required String message}) {
    return _remoteDataSource.sendMessage(message: message);
  }
}
