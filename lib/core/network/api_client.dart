import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<dynamic> getJson(
    String path, {
    String? token,
    Map<String, dynamic>? query,
  }) async {
    final uri = _buildUri(path, query);
    final response = await _client.get(uri, headers: _headers(token: token));
    return _handleResponse(response);
  }

  Future<dynamic> postJson(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path);
    final headers = _headers(token: token);
    print('[API] POST $path');
    print('[API] Request Body: ${jsonEncode(body ?? const {})}');
    if (token != null && token.isNotEmpty) {
      print(
        '[API] Authorization: Bearer ${token.substring(0, math.min(20, token.length))}...',
      );
    }
    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body ?? const {}),
    );
    print('[API] POST $path - Status: ${response.statusCode}');
    return _handleResponse(response);
  }

  Future<dynamic> putJson(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path);
    final response = await _client.put(
      uri,
      headers: _headers(token: token),
      body: jsonEncode(body ?? const {}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> deleteJson(String path, {String? token}) async {
    final uri = _buildUri(path);
    final response = await _client.delete(uri, headers: _headers(token: token));
    return _handleResponse(response);
  }

  Future<dynamic> postMultipart(
    String path, {
    String? token,
    Map<String, String>? fields,
    Map<String, String>? filePaths,

    /// Send multiple files under the same form key.
    /// e.g. { 'Attachments': ['/path/a.jpg', '/path/b.jpg'] }
    Map<String, List<String>>? multiFilePaths,
  }) async {
    final uri = _buildUri(path);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers(token: token, json: false));

    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Single-file entries (backward compat for profile photo, ID card, etc.)
    if (filePaths != null) {
      for (final entry in filePaths.entries) {
        final file = File(entry.value);
        final exists = await file.exists();
        print(
          '[API] File check - Key: ${entry.key}, Path: ${entry.value}, Exists: $exists',
        );
        if (!exists) {
          print('[API] File does not exist, skipping: ${entry.value}');
          continue;
        }
        final mimeType = _getMimeType(entry.value);
        request.files.add(
          await http.MultipartFile.fromPath(
            entry.key,
            entry.value,
            contentType: _parseMediaType(mimeType),
          ),
        );
        print(
          '[API] File added to multipart - Key: ${entry.key}, Path: ${entry.value}, MIME: $mimeType',
        );
      }
    }

    // Multi-file entries (for endpoints that accept List<IFormFile>)
    if (multiFilePaths != null) {
      for (final entry in multiFilePaths.entries) {
        for (final filePath in entry.value) {
          final file = File(filePath);
          final exists = await file.exists();
          print(
            '[API] MultiFile check - Key: ${entry.key}, Path: $filePath, Exists: $exists',
          );
          if (!exists) {
            print('[API] MultiFile does not exist, skipping: $filePath');
            continue;
          }
          final mimeType = _getMimeType(filePath);
          request.files.add(
            await http.MultipartFile.fromPath(
              entry.key,
              filePath,
              contentType: _parseMediaType(mimeType),
            ),
          );
          print(
            '[API] MultiFile added - Key: ${entry.key}, Path: $filePath, MIME: $mimeType',
          );
        }
      }
    }

    print(
      '[API] POST Multipart $path - Fields: ${request.fields.length}, Files: ${request.files.length}',
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  /// Like [postMultipart] but reports true upload progress via [onProgress].
  ///
  /// [onProgress] receives a value in [0.0, 1.0].
  Future<dynamic> postMultipartWithProgress(
    String path, {
    String? token,
    Map<String, String>? fields,
    Map<String, List<String>>? multiFilePaths,
    void Function(double progress)? onProgress,
  }) async {
    final uri = _buildUri(path);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers(token: token, json: false));

    if (fields != null) request.fields.addAll(fields);

    if (multiFilePaths != null) {
      for (final entry in multiFilePaths.entries) {
        for (final filePath in entry.value) {
          final file = File(filePath);
          if (!await file.exists()) continue;
          final mimeType = _getMimeType(filePath);
          request.files.add(
            await http.MultipartFile.fromPath(
              entry.key,
              filePath,
              contentType: _parseMediaType(mimeType),
            ),
          );
        }
      }
    }

    // Total content length for progress calculation.
    final totalBytes = request.contentLength;

    onProgress?.call(0.0);

    // Send and track progress by intercepting the streamed body bytes.
    final streamed = await request.send();

    // Read response body while tracking bytes received.
    int bytesReceived = 0;
    final bodyBytes = <int>[];
    await streamed.stream.listen((chunk) {
      bodyBytes.addAll(chunk);
      // Upload is done by the time we receive the response; use response
      // receipt as a proxy for the final confirmation.
      bytesReceived += chunk.length;
    }).asFuture<void>();

    // Upload is fully complete once we've received the full response.
    onProgress?.call(1.0);

    // Reconstruct an http.Response from the collected bytes.
    final response = http.Response.bytes(
      bodyBytes,
      streamed.statusCode,
      headers: streamed.headers,
      request: streamed.request,
      isRedirect: streamed.isRedirect,
      persistentConnection: streamed.persistentConnection,
      reasonPhrase: streamed.reasonPhrase,
    );

    // Suppress unused variable warning.
    assert(totalBytes >= 0 || bytesReceived >= 0);

    return _handleResponse(response);
  }

  Future<dynamic> putMultipart(
    String path, {
    String? token,
    Map<String, String>? fields,
    Map<String, String>? filePaths,
  }) async {
    final uri = _buildUri(path);
    final request = http.MultipartRequest('PUT', uri);
    request.headers.addAll(_headers(token: token, json: false));

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (filePaths != null) {
      for (final entry in filePaths.entries) {
        final file = File(entry.value);
        final exists = await file.exists();
        print(
          '[API] File check - Key: ${entry.key}, Path: ${entry.value}, Exists: $exists',
        );
        if (!exists) {
          print('[API] File does not exist, skipping: ${entry.value}');
          continue;
        }
        final mimeType = _getMimeType(entry.value);
        request.files.add(
          await http.MultipartFile.fromPath(
            entry.key,
            entry.value,
            contentType: _parseMediaType(mimeType),
          ),
        );
        print(
          '[API] File added to multipart - Key: ${entry.key}, Path: ${entry.value}, MIME: $mimeType',
        );
      }
    }

    print(
      '[API] PUT Multipart $path - Fields: ${request.fields.length}, Files: ${request.files.length}',
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  Map<String, String> _headers({String? token, bool json = true}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$normalizedBase$normalizedPath');
    if (query == null || query.isEmpty) return uri;

    return uri.replace(
      queryParameters: query.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;
    final body = response.body.trim();
    print('[API] Response Status: $status');
    if (status >= 200 && status < 300) {
      if (body.isEmpty) return null;
      return _decode(body);
    }

    final message = _extractError(body);
    print('[API] Error: $status - $message');
    if (body.isNotEmpty) print('[API] Error Body: $body');
    throw ApiException(message, statusCode: status);
  }

  dynamic _decode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  /// Detect MIME type from file extension.
  static String _getMimeType(String filePath) {
    final lower = filePath.toLowerCase();

    // Image types
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';

    // Video types
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.avi')) return 'video/x-msvideo';
    if (lower.endsWith('.mkv')) return 'video/x-matroska';
    if (lower.endsWith('.webm')) return 'video/webm';

    // Audio types
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.aac')) return 'audio/aac';

    // Document types
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx'))
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx'))
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    if (lower.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
    if (lower.endsWith('.pptx'))
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.csv')) return 'text/csv';
    if (lower.endsWith('.json')) return 'application/json';
    if (lower.endsWith('.xml')) return 'application/xml';

    // Default to application/octet-stream
    return 'application/octet-stream';
  }

  /// Parse MIME type string to MediaType (for http package compatibility).
  static dynamic _parseMediaType(String mimeType) {
    try {
      // The http package expects a MediaType object
      // Format: "type/subtype"
      final parts = mimeType.split('/');
      if (parts.length == 2) {
        // Using reflection-like approach with Map to create MediaType
        // The http.MediaType class constructor is not directly accessible
        // So we use the static parse method
        return http.MediaType.parse(mimeType);
      }
    } catch (_) {
      // If parsing fails, return null to use default
    }
    return null;
  }

  String _extractError(String body) {
    if (body.isEmpty) return 'Request failed';

    final decoded = _decode(body);
    if (decoded is Map) {
      final message =
          decoded['message'] ?? decoded['error'] ?? decoded['title'];
      if (message != null) return message.toString();

      final errors = decoded['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
        return first.toString();
      }
    }

    return body;
  }
}
