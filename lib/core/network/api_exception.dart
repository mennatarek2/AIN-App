class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode == null ? 'unknown' : statusCode.toString();
    return 'ApiException($code): $message';
  }
}
