import '../../../../core/network/api_config.dart';
import '../../domain/entities/report_comment.dart';

class CommentModel {
  const CommentModel({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    required this.createdAt,
    required this.isDeleted,
    required this.totalLikes,
    required this.isLikedByCaller,
    this.parentCommentId,
    this.replies = const [],
  });

  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final DateTime createdAt;
  final bool isDeleted;
  final int totalLikes;
  final bool isLikedByCaller;
  final String? parentCommentId;
  final List<CommentModel> replies;

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'] ?? json['children'];
    final replies = rawReplies is List
        ? rawReplies
              .whereType<Map>()
              .map((r) => CommentModel.fromJson(Map<String, dynamic>.from(r)))
              .toList()
        : <CommentModel>[];

    final rawPhoto =
        json['authorPhoto'] ??
        json['authorPhotoUrl'] ??
        json['profilePhotoUrl'] ??
        json['authorAvatar'];
    String? photoUrl;
    if (rawPhoto is String && rawPhoto.trim().isNotEmpty) {
      final trimmed = rawPhoto.trim();
      photoUrl = trimmed.startsWith('http')
          ? trimmed
          : '${ApiConfig.baseUrl}$trimmed';
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
      authorPhoto: photoUrl,
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
      isDeleted: _parseBool(json['isDeleted'] ?? json['deleted'] ?? false),
      totalLikes: _parseInt(json['totalLikes'] ?? json['likesCount'] ?? 0),
      isLikedByCaller: _parseBool(
        json['isLikedByCaller'] ??
            json['isLikedByCalller'] ??
            json['isLiked'] ??
            false,
      ),
      parentCommentId: json['parentCommentId']?.toString(),
      replies: replies,
    );
  }

  ReportComment toEntity() => ReportComment(
    id: id,
    content: content,
    authorId: authorId,
    authorName: authorName,
    authorPhoto: authorPhoto,
    createdAt: createdAt,
    isDeleted: isDeleted,
    totalLikes: totalLikes,
    isLikedByCaller: isLikedByCaller,
    parentCommentId: parentCommentId,
    replies: replies.map((r) => r.toEntity()).toList(),
  );

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    final normalized = value?.toString().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
}
