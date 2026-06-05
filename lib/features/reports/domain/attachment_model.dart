import 'package:ain_graduation_project/core/network/api_config.dart';

/// Model matching the backend `AttachmentDto`.
///
/// The backend returns attachments as:
/// ```json
/// { "id": "guid", "fileName": "photo.jpg", "filePath": "/uploads/photo.jpg", "fileSize": "1024" }
/// ```
class AttachmentModel {
  const AttachmentModel({
    required this.id,
    required this.fileName,
    required this.filePath,
    this.fileSize = '',
  });

  /// Unique identifier for the attachment (GUID from backend).
  final String id;

  /// Original file name (e.g. "photo.jpg").
  final String fileName;

  /// Relative or absolute path as returned by the API.
  final String filePath;

  /// File size as a string (e.g. "1024").
  final String fileSize;

  /// Returns the fully resolved URL for displaying the attachment.
  ///
  /// If [filePath] is already an absolute URL, returns it as-is.
  /// If it's a relative path (e.g. "/uploads/photo.jpg"), prepends the base URL.
  String get fullUrl {
    final trimmed = filePath.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final baseUrl = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;

    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$baseUrl$path';
  }

  /// Parse from backend API JSON (AttachmentDto).
  factory AttachmentModel.fromApiJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      filePath: json['filePath']?.toString() ?? '',
      fileSize: json['fileSize']?.toString() ?? '',
    );
  }

  /// Parse from local cache JSON.
  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      filePath: json['filePath']?.toString() ?? '',
      fileSize: json['fileSize']?.toString() ?? '',
    );
  }

  /// Serialize for local cache storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
    };
  }

  AttachmentModel copyWith({
    String? id,
    String? fileName,
    String? filePath,
    String? fileSize,
  }) {
    return AttachmentModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  @override
  String toString() =>
      'AttachmentModel(id: $id, fileName: $fileName, filePath: $filePath)';
}
