class ReportComment {
  const ReportComment({
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
  final List<ReportComment> replies;

  ReportComment copyWith({
    String? id,
    String? content,
    String? authorId,
    String? authorName,
    String? authorPhoto,
    DateTime? createdAt,
    bool? isDeleted,
    int? totalLikes,
    bool? isLikedByCaller,
    String? parentCommentId,
    List<ReportComment>? replies,
  }) {
    return ReportComment(
      id: id ?? this.id,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhoto: authorPhoto ?? this.authorPhoto,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      totalLikes: totalLikes ?? this.totalLikes,
      isLikedByCaller: isLikedByCaller ?? this.isLikedByCaller,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
    );
  }
}
