import '../entities/like_result.dart';
import '../entities/report_comment.dart';
import '../entities/user_trust.dart';

abstract interface class ISocialRepository {
  Future<List<ReportComment>> getComments(String reportId);

  Future<ReportComment> addComment(
    String reportId,
    String content,
    String? parentCommentId,
  );

  Future<void> deleteComment(String commentId);

  Future<LikeResult> toggleReportLike(String reportId);

  Future<LikeResult> getReportLikes(String reportId);

  Future<CommentLikeResult> toggleCommentLike(String commentId);

  Future<UserTrust> getMyTrust();

  Future<UserTrust> getUserTrust(String userId);
}
