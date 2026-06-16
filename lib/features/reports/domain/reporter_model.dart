import 'package:ain_graduation_project/core/network/api_config.dart';

/// Reporter information returned by the public reports API.
class ReporterModel {
  const ReporterModel({required this.name, this.profilePhotoUrl});

  final String name;
  final String? profilePhotoUrl;

  /// Fully resolved profile photo URL for display.
  String? get resolvedPhotoUrl {
    final trimmed = profilePhotoUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final baseUrl = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$baseUrl$path';
  }

  factory ReporterModel.fromApiJson(Map<String, dynamic> json) {
    return ReporterModel(
      name: json['name']?.toString() ?? '',
      profilePhotoUrl: json['profilePhotoUrl']?.toString(),
    );
  }

  factory ReporterModel.fromJson(Map<String, dynamic> json) {
    return ReporterModel(
      name: json['name']?.toString() ?? '',
      profilePhotoUrl: json['profilePhotoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'profilePhotoUrl': profilePhotoUrl};
  }
}
