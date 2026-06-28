import '../../domain/entities/like_result.dart';

class LikeResultModel {
  const LikeResultModel({
    required this.totalLikes,
    required this.isLikedByCaller,
  });

  final int totalLikes;
  final bool isLikedByCaller;

  factory LikeResultModel.fromJson(Map<String, dynamic> json) {
    final likes = _parseInt(
      json['likeCount'] ??
          json['totalLikes'] ??
          json['likesCount'] ??
          json['count'] ??
          json['likes'] ??
          0,
    );
    final isLiked = _parseBool(
      json['isLikedByCurrentUser'] ??
          json['isLikedByCaller'] ??
          json['isLikedByCalller'] ??
          json['isLiked'] ??
          json['likedByMe'] ??
          false,
    );
    return LikeResultModel(totalLikes: likes, isLikedByCaller: isLiked);
  }

  LikeResult toEntity() => LikeResult(
    totalLikes: totalLikes,
    isLikedByCaller: isLikedByCaller,
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

class CommentLikeResultModel {
  const CommentLikeResultModel({
    required this.totalLikes,
    required this.isLikedByCaller,
  });

  final int totalLikes;
  final bool isLikedByCaller;

  factory CommentLikeResultModel.fromJson(Map<String, dynamic> json) {
    return CommentLikeResultModel(
      totalLikes: LikeResultModel._parseInt(
        json['likeCount'] ??
            json['totalLikes'] ??
            json['likesCount'] ??
            json['count'] ??
            json['likes'] ??
            0,
      ),
      isLikedByCaller: LikeResultModel._parseBool(
        json['isLikedByCurrentUser'] ??
            json['isLikedByCaller'] ??
            json['isLikedByCalller'] ??
            json['isLiked'] ??
            json['likedByMe'] ??
            false,
      ),
    );
  }

  CommentLikeResult toEntity() => CommentLikeResult(
    totalLikes: totalLikes,
    isLikedByCaller: isLikedByCaller,
  );
}
