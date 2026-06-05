class ProfileException implements Exception {
  ProfileException(this.message, [this.code]);

  final String message;
  final int? code;

  @override
  String toString() => 'ProfileException(code: $code, message: $message)';
}
