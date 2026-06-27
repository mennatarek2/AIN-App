import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/chat_message_model.dart';
import '../../domain/repositories/chatbot_repository.dart';
import 'chatbot_data_providers.dart';

class ChatbotState {
  const ChatbotState({
    this.messages = const [],
    this.isSending = false,
  });

  final List<ChatMessageModel> messages;
  final bool isSending;

  ChatbotState copyWith({
    List<ChatMessageModel>? messages,
    bool? isSending,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatbotNotifier extends StateNotifier<ChatbotState> {
  ChatbotNotifier(this._repository) : super(const ChatbotState());

  final ChatbotRepository _repository;

  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isSending) return;

    final userMessage = ChatMessageModel(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      content: text,
      role: ChatMessageRole.user,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
    );

    try {
      final response = await _repository.sendMessage(message: text);
      if (!mounted) return;

      final assistantMessage = ChatMessageModel(
        id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
        content: response.message,
        role: ChatMessageRole.assistant,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isSending: false,
      );
    } catch (e) {
      if (!mounted) return;

      final errorMessage = ChatMessageModel(
        id: 'error-${DateTime.now().microsecondsSinceEpoch}',
        content: _errorMessage(e),
        role: ChatMessageRole.error,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isSending: false,
      );
    }
  }

  void clearConversation() {
    state = const ChatbotState();
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }
}

final chatbotProvider =
    StateNotifierProvider.autoDispose<ChatbotNotifier, ChatbotState>((ref) {
      return ChatbotNotifier(ref.watch(chatbotRepositoryProvider));
    });
