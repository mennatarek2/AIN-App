import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/chat_response_model.dart';

class ChatbotRemoteDataSource {
  ChatbotRemoteDataSource(this._client, {required this.readToken});

  final ApiClient _client;
  final Future<String?> Function() readToken;

  Future<ChatResponseModel> sendMessage({required String message}) async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }

    final response = await _client.postJson(
      ApiEndpoints.aiChat,
      token: token,
      body: {'Message': message},
    );

    return ChatResponseModel.fromApiJson(response);
  }
}
