import 'package:ain_graduation_project/core/network/api_config.dart';

/// Domain model for a single comment (or reply) on a report.
class CommentModel {
  const CommentModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    required this.createdAt,
    this.replies = const [],
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final DateTime createdAt;
  final List<CommentModel> replies;

  factory CommentModel.fromApiJson(Map<String, dynamic> json) {
    // Parse replies recursively
    final rawReplies = json['replies'] ?? json['children'];
    final replies = rawReplies is List
        ? rawReplies
              .whereType<Map>()
              .map(
                (r) => CommentModel.fromApiJson(Map<String, dynamic>.from(r)),
              )
              .toList()
        : <CommentModel>[];

    // Resolve author photo URL
    final rawPhoto =
        json['authorPhotoUrl'] ??
        json['profilePhotoUrl'] ??
        json['authorAvatar'];
    String? photoUrl;
    if (rawPhoto is String && rawPhoto.trim().isNotEmpty) {
      final trimmed = rawPhoto.trim();
      photoUrl = trimmed.startsWith('http') ? trimmed : '${ApiConfig.baseUrl}$trimmed';
    }

    return CommentModel(
      id: json['id']?.toString() ?? '',
      authorId:
          json['authorId']?.toString() ??
          json['userId']?.toString() ??
          json['createdById']?.toString() ??
          '',
      authorName:
          json['authorName']?.toString() ??
          json['userName']?.toString() ??
          json['name']?.toString() ??
          'مستخدم',
      authorPhotoUrl: photoUrl,
      content:
          json['content']?.toString() ??
          json['text']?.toString() ??
          json['body']?.toString() ??
          '',
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ??
            json['createdDate']?.toString() ??
            '',
          ) ??
          DateTime.now(),
      replies: replies,
    );
  }
}
