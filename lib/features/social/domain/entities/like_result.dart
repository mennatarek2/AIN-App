class LikeResult {
  const LikeResult({
    required this.totalLikes,
    required this.isLikedByCaller,
  });

  final int totalLikes;
  final bool isLikedByCaller;

  LikeResult copyWith({int? totalLikes, bool? isLikedByCaller}) {
    return LikeResult(
      totalLikes: totalLikes ?? this.totalLikes,
      isLikedByCaller: isLikedByCaller ?? this.isLikedByCaller,
    );
  }
}

class CommentLikeResult {
  const CommentLikeResult({
    required this.totalLikes,
    required this.isLikedByCaller,
  });

  final int totalLikes;
  final bool isLikedByCaller;

  CommentLikeResult copyWith({int? totalLikes, bool? isLikedByCaller}) {
    return CommentLikeResult(
      totalLikes: totalLikes ?? this.totalLikes,
      isLikedByCaller: isLikedByCaller ?? this.isLikedByCaller,
    );
  }
}
