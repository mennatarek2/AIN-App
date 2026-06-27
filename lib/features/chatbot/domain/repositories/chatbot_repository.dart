import '../../data/models/chat_response_model.dart';

abstract class ChatbotRepository {
  Future<ChatResponseModel> sendMessage({required String message});
}
