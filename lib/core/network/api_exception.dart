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
        // Try common error message keys in priority order.
        // 'message' / 'error' / 'title'  → standard REST / RFC 7807
        // 'Message'                       → PascalCase .NET responses
        // 'Details' / 'detail'            → ASP.NET 500 / RFC 7807 detail
        // 'errors'                        → ASP.NET validation error map
        final message =
            decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            decoded['title']?.toString() ??
            decoded['Message']?.toString() ??
            decoded['Details']?.toString() ??
            _flattenErrors(decoded['errors']) ??
            'Unknown error';

        final detail =
            decoded['detail']?.toString() ??
            decoded['Details']?.toString();

        return ApiException(
          message,
          statusCode: response.statusCode,
          detail: detail,
        );
      }
    } catch (_) {}

    return ApiException(body, statusCode: response.statusCode);
  }

  /// Flattens an ASP.NET ModelState errors map into a single string.
  /// e.g. {"Field": ["error1", "error2"]} → "Field: error1, error2"
  static String? _flattenErrors(dynamic errors) {
    if (errors == null) return null;
    if (errors is Map) {
      final parts = <String>[];
      for (final entry in errors.entries) {
        final msgs = entry.value;
        if (msgs is List && msgs.isNotEmpty) {
          parts.add('${entry.key}: ${msgs.join(', ')}');
        } else if (msgs != null) {
          parts.add('${entry.key}: $msgs');
        }
      }
      return parts.isNotEmpty ? parts.join(' | ') : null;
    }
    return null;
  }


  @override
  String toString() {
    final code = statusCode == null ? 'unknown' : statusCode.toString();
    return 'ApiException($code): $displayMessage';
  }
}
