enum ChatMessageRole { user, assistant, error }

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String content;
  final ChatMessageRole role;
  final DateTime createdAt;

  bool get isUser => role == ChatMessageRole.user;
  bool get isError => role == ChatMessageRole.error;
}
