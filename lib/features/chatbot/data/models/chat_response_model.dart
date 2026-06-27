class ChatResponseModel {
  const ChatResponseModel({required this.message});

  final String message;

  factory ChatResponseModel.fromApiJson(dynamic response) {
    if (response is String && response.trim().isNotEmpty) {
      return ChatResponseModel(message: response.trim());
    }

    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      final text = _readString(map, const [
        'response',
        'reply',
        'message',
        'content',
        'answer',
        'text',
        'result',
      ]);

      if (text != null && text.isNotEmpty) {
        return ChatResponseModel(message: text);
      }

      final nested = map['data'];
      if (nested is Map) {
        final nestedText = _readString(
          Map<String, dynamic>.from(nested),
          const ['response', 'reply', 'message', 'content', 'answer', 'text'],
        );
        if (nestedText != null && nestedText.isNotEmpty) {
          return ChatResponseModel(message: nestedText);
        }
      }
    }

    throw const FormatException('Unexpected AI chat response format');
  }

  static String? _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
