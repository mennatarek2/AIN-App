import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/attachment_model.dart';
import '../../domain/report_model.dart';

class ReportRemoteDataSource {
  ReportRemoteDataSource(this._client, {required this.readToken});

  final ApiClient _client;
  final Future<String?> Function() readToken;

  /// Submit a new report to the backend.
  ///
  /// The backend `CreateReportDto` uses `[FromForm]` binding, so we send a
  /// multipart request. Attachments are sent under the key `Attachments` to
  /// match the ASP.NET model binder for `List<IFormFile> Attachments`.
  Future<ReportModel> submitReport(ReportModel report) async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }

    final subCategoryId = report.subCategoryId?.trim();
    if (subCategoryId == null || subCategoryId.isEmpty) {
      throw Exception('Missing sub category id');
    }

    final fields = <String, String>{
      'Title': report.title,
      'Description': report.description,
      'SubCategoryId': subCategoryId,
      'Latitude': report.latitude.toString(),
      'Longitude': report.longitude.toString(),
      'Visibility': report.visibility ?? 'Public',
    };

    // Build multi-file payload from the report's legacy imagePath
    // (single file for locally created reports) or from attachment paths.
    final attachmentPaths = _buildAttachmentPaths(report);

    print('[API] Submitting report:');
    print('  Title: ${report.title}');
    print('  Description: ${report.description}');
    print('  SubCategoryId: $subCategoryId');
    print('  Location: ${report.latitude}, ${report.longitude}');
    print('  Visibility: ${report.visibility}');
    print('  Attachment paths: $attachmentPaths');
    print('  Endpoint: ${ApiEndpoints.reports}');

    try {
      final response = await _client.postMultipart(
        ApiEndpoints.reports,
        token: token,
        fields: fields,
        // Use multiFilePaths to send under the 'Attachments' key
        multiFilePaths: attachmentPaths.isNotEmpty
            ? {'Attachments': attachmentPaths}
            : null,
      );

      print('[API] Report submitted successfully. Response: $response');

      // Parse returned attachments from the response and return an updated model
      if (response is Map) {
        final responseMap = Map<String, dynamic>.from(response);
        final rawAttachments = responseMap['attachments'];
        if (rawAttachments is List && rawAttachments.isNotEmpty) {
          print('[API] Response attachments: ${rawAttachments.length} items');
          final attachments = rawAttachments
              .whereType<Map>()
              .map(
                (a) => AttachmentModel.fromApiJson(
                  Map<String, dynamic>.from(a),
                ),
              )
              .toList();
          return report.copyWith(attachments: attachments, isSynced: true);
        }
      }

      return report.copyWith(isSynced: true);
    } catch (e) {
      print('[API] Report submission failed: $e');
      rethrow;
    }
  }

  Future<List<ReportModel>> fetchPublicReports({
    int pageNumber = 1,
    int pageSize = 10,
    String? categoryId,
    String? status,
    String? search,
  }) async {
    final query = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
    if (categoryId != null && categoryId.isNotEmpty) {
      query['categoryId'] = categoryId;
    }
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }
    final response = await _client.getJson(
      ApiEndpoints.reportsPublic,
      query: query,
    );
    return _parseReportList(response);
  }

  Future<List<ReportModel>> fetchVisibleReports({
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      return const [];
    }

    final response = await _client.getJson(
      ApiEndpoints.reportsVisible,
      token: token,
      query: {'pageNumber': pageNumber, 'pageSize': pageSize},
    );
    return _parseReportList(response);
  }

  Future<ReportModel?> fetchReportById(String id) async {
    final token = await readToken();
    final response = await _client.getJson(
      ApiEndpoints.reportById(id),
      token: token, // send token if available (for own/confidential reports)
    );
    final map = _extractMap(response);
    if (map == null) return null;
    return ReportModel.fromApiJson(map);
  }

  /// Update a report's visibility. Requires auth.
  Future<void> updateVisibility(String id, String visibility) async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }
    await _client.putJson(
      ApiEndpoints.reportVisibility(id),
      token: token,
      body: {'visibility': visibility},
    );
  }

  /// Delete a report. Requires auth. Expects 204 on success.
  Future<void> deleteReport(String id) async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }
    await _client.deleteJson(ApiEndpoints.reportDelete(id), token: token);
  }

  /// Fetch the authenticated user's own reports.
  ///
  /// Supports optional [statusFilter] (e.g. `"UnderReview"`, `"Resolved"`)
  /// and standard pagination via [pageNumber] / [pageSize].
  Future<List<ReportModel>> fetchMyReports({
    int pageNumber = 1,
    int pageSize = 10,
    String? statusFilter,
  }) async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) return const [];

    final query = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query['status'] = statusFilter;
    }

    final response = await _client.getJson(
      ApiEndpoints.myReports,
      token: token,
      query: query,
    );
    return _parseReportList(response);
  }

  /// Submit a new report and report upload progress.
  ///
  /// [onProgress] is called with values in [0.0, 1.0].
  /// Pass [attachmentPaths] explicitly to include multiple local files;
  /// falls back to [_buildAttachmentPaths] for legacy single-image reports.
  Future<ReportModel> submitReportWithProgress(
    ReportModel report, {
    void Function(double)? onProgress,
    List<String>? attachmentPaths,
  }) async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }

    final subCategoryId = report.subCategoryId?.trim();
    if (subCategoryId == null || subCategoryId.isEmpty) {
      throw Exception('Missing sub category id');
    }

    final fields = <String, String>{
      'Title': report.title,
      'Description': report.description,
      'SubCategoryId': subCategoryId,
      'Latitude': report.latitude.toString(),
      'Longitude': report.longitude.toString(),
      'Visibility': report.visibility ?? 'Public',
    };

    final paths = attachmentPaths ?? _buildAttachmentPaths(report);

    final response = await _client.postMultipartWithProgress(
      ApiEndpoints.reports,
      token: token,
      fields: fields,
      multiFilePaths: paths.isNotEmpty ? {'Attachments': paths} : null,
      onProgress: onProgress,
    );

    if (response is Map) {
      final responseMap = Map<String, dynamic>.from(response);
      final rawAttachments = responseMap['attachments'];
      if (rawAttachments is List && rawAttachments.isNotEmpty) {
        final attachments = rawAttachments
            .whereType<Map>()
            .map(
              (a) => AttachmentModel.fromApiJson(
                Map<String, dynamic>.from(a),
              ),
            )
            .toList();
        return report.copyWith(attachments: attachments, isSynced: true);
      }
    }
    return report.copyWith(isSynced: true);
  }

  List<ReportModel> _parseReportList(dynamic response) {
    final list = _extractList(response);
    if (list == null) return const [];

    return list
        .whereType<Map>()
        .map((item) => ReportModel.fromApiJson(Map<String, dynamic>.from(item)))
        .where((report) => report.id.isNotEmpty)
        .toList();
  }

  List<dynamic>? _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      final candidate =
          payload['data'] ?? payload['items'] ?? payload['result'];
      if (candidate is List) return candidate;

      for (final value in payload.values) {
        final nested = _extractList(value);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractMap(dynamic payload) {
    if (payload is Map) {
      if (payload.containsKey('id')) {
        return Map<String, dynamic>.from(payload);
      }
      final candidate = payload['data'] ?? payload['result'];
      if (candidate is Map) return Map<String, dynamic>.from(candidate);

      for (final value in payload.values) {
        final nested = _extractMap(value);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  /// Build the list of local file paths to attach to the request.
  ///
  /// For locally created reports: uses `_legacyImagePath` (single file).
  /// Skips network URLs and empty paths.
  List<String> _buildAttachmentPaths(ReportModel report) {
    final paths = <String>[];

    // Check the legacy internal path (only set for locally-created reports)
    // We reach it via imagePath only if there are no attachments yet
    final legacy = report.attachments.isEmpty ? report.imagePath.trim() : '';

    if (legacy.isNotEmpty && _isLocalFilePath(legacy)) {
      paths.add(legacy);
    }

    return paths;
  }

  bool _isLocalFilePath(String path) {
    if (path.isEmpty) return false;
    // Reject network URLs and asset paths
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('assets/')) {
      return false;
    }
    return true;
  }
}
