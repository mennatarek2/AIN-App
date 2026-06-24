import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  String get displayMessage => detail ?? message;

  factory ApiException.fromResponse(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return ApiException(
        'Request failed',
        statusCode: response.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return ApiException(
          decoded['message']?.toString() ??
              decoded['error']?.toString() ??
              decoded['title']?.toString() ??
              'Unknown error',
          statusCode: response.statusCode,
          detail: decoded['detail']?.toString(),
        );
      }
    } catch (_) {}

    return ApiException(body, statusCode: response.statusCode);
  }

  @override
  String toString() {
    final code = statusCode == null ? 'unknown' : statusCode.toString();
    return 'ApiException($code): $displayMessage';
  }
}
