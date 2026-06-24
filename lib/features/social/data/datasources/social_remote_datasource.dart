import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/comment_model.dart';
import '../models/like_result_model.dart';
import '../models/user_trust_model.dart';

class SocialRemoteDataSource {
  const SocialRemoteDataSource(this._client, {required this.readToken});

  final ApiClient _client;
  final Future<String?> Function() readToken;

  Future<List<CommentModel>> getComments(String reportId) async {
    final token = await readToken();
    final response = await _client.getJson(
      ApiEndpoints.reportComments(reportId),
      token: token,
      jsonContentType: false,
    );
    return _parseComments(response);
  }

  Future<CommentModel> addComment(
    String reportId,
    String content, {
    String? parentCommentId,
  }) async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }
    final body = <String, dynamic>{'content': content};
    if (parentCommentId != null && parentCommentId.isNotEmpty) {
      body['parentCommentId'] = parentCommentId;
    }
    final response = await _client.postJson(
      ApiEndpoints.reportComments(reportId),
      token: token,
      body: body,
    );
    if (response is Map) {
      return CommentModel.fromJson(Map<String, dynamic>.from(response));
    }
    throw Exception('Invalid comment response');
  }

  Future<void> deleteComment(String commentId) async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }
    await _client.deleteJson(
      ApiEndpoints.commentDelete(commentId),
      token: token,
    );
  }

  Future<LikeResultModel> toggleReportLike(String reportId) async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }
    final response = await _client.postJson(
      ApiEndpoints.reportLike(reportId),
      token: token,
      body: const {},
    );
    return _parseLikeResult(response);
  }

  Future<LikeResultModel> getReportLikes(String reportId) async {
    final token = await readToken();
    final response = await _client.getJson(
      ApiEndpoints.reportLikes(reportId),
      token: token,
    );
    return _parseLikeResult(response);
  }

  Future<CommentLikeResultModel> toggleCommentLike(String commentId) async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }
    final response = await _client.postJson(
      ApiEndpoints.commentLike(commentId),
      token: token,
      body: const {},
    );
    if (response is Map) {
      return CommentLikeResultModel.fromJson(
        Map<String, dynamic>.from(response),
      );
    }
    return const CommentLikeResultModel(totalLikes: 0, isLikedByCaller: false);
  }

  Future<UserTrustModel> getMyTrust() async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }
    final response = await _client.getJson(
      ApiEndpoints.myTrust,
      token: token,
    );
    return _parseUserTrust(response);
  }

  Future<UserTrustModel> getUserTrust(String userId) async {
    final token = await readToken();
    final response = await _client.getJson(
      ApiEndpoints.userTrust(userId),
      token: token,
    );
    return _parseUserTrust(response);
  }

  LikeResultModel _parseLikeResult(dynamic response) {
    if (response is Map) {
      return LikeResultModel.fromJson(Map<String, dynamic>.from(response));
    }
    return const LikeResultModel(totalLikes: 0, isLikedByCaller: false);
  }

  UserTrustModel _parseUserTrust(dynamic response) {
    if (response is Map<String, dynamic>) {
      return UserTrustModel.fromJson(response);
    }
    if (response is Map) {
      return UserTrustModel.fromJson(Map<String, dynamic>.from(response));
    }
    throw Exception('Invalid trust response');
  }

  List<CommentModel> _parseComments(dynamic response) {
    List<dynamic>? list;
    if (response is List) {
      list = response;
    } else if (response is Map) {
      final candidate =
          response['data'] ??
          response['items'] ??
          response['result'] ??
          response['comments'];
      if (candidate is List) list = candidate;
    }
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((item) => CommentModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
