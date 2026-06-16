/// Response from PUT /api/Profile/update-profile
class UpdateProfileResponse {
  const UpdateProfileResponse({
    required this.isSuccess,
    this.errors = const {},
  });

  final bool isSuccess;
  final Map<String, dynamic> errors;

  factory UpdateProfileResponse.fromJson(Map<String, dynamic> json) {
    final rawErrors = json['errors'];
    final errors = rawErrors is Map
        ? Map<String, dynamic>.from(rawErrors)
        : <String, dynamic>{};

    return UpdateProfileResponse(
      isSuccess: json['isSuccess'] == true,
      errors: errors,
    );
  }

  String get errorMessage {
    if (errors.isEmpty) return 'فشل تحديث الملف الشخصي';
    return errors.values
        .map((value) {
          if (value is List) {
            return value.map((item) => item.toString()).join('\n');
          }
          return value.toString();
        })
        .join('\n');
  }
}
