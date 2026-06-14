import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/comment_model.dart';

/// Handles social interactions (comments, likes) for reports.
class SocialRemoteDataSource {
  const SocialRemoteDataSource(this._client, {required this.readToken});

  final ApiClient _client;
  final Future<String?> Function() readToken;

  // ---------------------------------------------------------------------------
  // Comments
  // ---------------------------------------------------------------------------

  Future<List<CommentModel>> fetchComments(String reportId) async {
    final token = await readToken();
    final response = await _client.getJson(
      ApiEndpoints.reportComments(reportId),
      token: token,
    );
    return _parseComments(response);
  }

  Future<CommentModel> postComment(
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
      return CommentModel.fromApiJson(Map<String, dynamic>.from(response));
    }
    throw Exception('Invalid comment response');
  }

  // ---------------------------------------------------------------------------
  // Likes (toggle)
  // ---------------------------------------------------------------------------

  /// Toggle like. Returns new like count from the response, or -1 if unknown.
  Future<int> toggleLike(String reportId) async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }
    final response = await _client.postJson(
      ApiEndpoints.reportLike(reportId),
      token: token,
      body: {},
    );
    if (response is Map) {
      final count = response['likesCount'] ?? response['count'] ?? response['likes'];
      if (count is int) return count;
      if (count != null) return int.tryParse(count.toString()) ?? -1;
    }
    return -1;
  }

  // ---------------------------------------------------------------------------
  // Parsing helpers
  // ---------------------------------------------------------------------------

  List<CommentModel> _parseComments(dynamic response) {
    List<dynamic>? list;
    if (response is List) {
      list = response;
    } else if (response is Map) {
      final candidate =
          response['data'] ?? response['items'] ?? response['result'] ?? response['comments'];
      if (candidate is List) list = candidate;
    }
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((item) => CommentModel.fromApiJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
