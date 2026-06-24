import '../../domain/entities/like_result.dart';
import '../../domain/entities/report_comment.dart';
import '../../domain/entities/user_trust.dart';
import '../../domain/repositories/i_social_repository.dart';
import '../datasources/social_remote_datasource.dart';

class SocialRepositoryImpl implements ISocialRepository {
  const SocialRepositoryImpl({required this.remoteDataSource});

  final SocialRemoteDataSource remoteDataSource;

  @override
  Future<List<ReportComment>> getComments(String reportId) async {
    final models = await remoteDataSource.getComments(reportId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ReportComment> addComment(
    String reportId,
    String content,
    String? parentCommentId,
  ) async {
    final model = await remoteDataSource.addComment(
      reportId,
      content,
      parentCommentId: parentCommentId,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await remoteDataSource.deleteComment(commentId);
  }

  @override
  Future<LikeResult> toggleReportLike(String reportId) async {
    final model = await remoteDataSource.toggleReportLike(reportId);
    return model.toEntity();
  }

  @override
  Future<LikeResult> getReportLikes(String reportId) async {
    final model = await remoteDataSource.getReportLikes(reportId);
    return model.toEntity();
  }

  @override
  Future<CommentLikeResult> toggleCommentLike(String commentId) async {
    final model = await remoteDataSource.toggleCommentLike(commentId);
    return model.toEntity();
  }

  @override
  Future<UserTrust> getMyTrust() async {
    final model = await remoteDataSource.getMyTrust();
    return model.toEntity();
  }

  @override
  Future<UserTrust> getUserTrust(String userId) async {
    final model = await remoteDataSource.getUserTrust(userId);
    return model.toEntity();
  }
}
