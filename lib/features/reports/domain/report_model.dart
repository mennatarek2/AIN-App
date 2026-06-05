import 'package:ain_graduation_project/core/network/api_config.dart';
import 'package:flutter/material.dart';

import 'attachment_model.dart';

class ReportModel {
  const ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.submittedAgo,
    required this.fullDescription,
    required this.reportType,
    this.attachments = const [],
    String? imagePath,
    required this.progressIndex,
    required this.statusLabel,
    required this.statusColor,
    required this.latitude,
    required this.longitude,
    this.locationAddress,
    this.categoryName,
    this.subCategoryName,
    this.isSynced = true,
    this.localId,
    this.subCategoryId,
    this.visibility,
    this.authorityName,
    this.createdByName,
  }) : _legacyImagePath = imagePath;

  final String id;
  final String title;
  final String description;
  final String submittedAgo;
  final String fullDescription;
  final String reportType;

  /// All attachments associated with this report.
  final List<AttachmentModel> attachments;

  /// Legacy single image path (used for backward compat with local cache
  /// and for locally-created reports that haven't been synced yet).
  final String? _legacyImagePath;

  /// Returns the best available image path for display.
  /// Prefers the first attachment's fullUrl, falls back to legacy path.
  String get imagePath {
    if (attachments.isNotEmpty) {
      final url = attachments.first.fullUrl;
      if (url.isNotEmpty) return url;
    }
    return _legacyImagePath ?? '';
  }

  final int progressIndex;
  final String statusLabel;
  final Color statusColor;
  final double latitude;
  final double longitude;
  final String? locationAddress;
  final String? categoryName;
  final String? subCategoryName;
  final bool isSynced;
  final String? localId;
  final String? subCategoryId;
  final String? visibility;
  final String? authorityName;
  final String? createdByName;

  ReportModel copyWith({
    String? id,
    String? title,
    String? description,
    String? submittedAgo,
    String? fullDescription,
    String? reportType,
    List<AttachmentModel>? attachments,
    String? imagePath,
    int? progressIndex,
    String? statusLabel,
    Color? statusColor,
    double? latitude,
    double? longitude,
    String? locationAddress,
    String? categoryName,
    String? subCategoryName,
    bool? isSynced,
    String? localId,
    String? subCategoryId,
    String? visibility,
    String? authorityName,
    String? createdByName,
  }) {
    return ReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      submittedAgo: submittedAgo ?? this.submittedAgo,
      fullDescription: fullDescription ?? this.fullDescription,
      reportType: reportType ?? this.reportType,
      attachments: attachments ?? this.attachments,
      imagePath: imagePath ?? _legacyImagePath,
      progressIndex: progressIndex ?? this.progressIndex,
      statusLabel: statusLabel ?? this.statusLabel,
      statusColor: statusColor ?? this.statusColor,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
      categoryName: categoryName ?? this.categoryName,
      subCategoryName: subCategoryName ?? this.subCategoryName,
      isSynced: isSynced ?? this.isSynced,
      localId: localId ?? this.localId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      visibility: visibility ?? this.visibility,
      authorityName: authorityName ?? this.authorityName,
      createdByName: createdByName ?? this.createdByName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'submittedAgo': submittedAgo,
      'fullDescription': fullDescription,
      'reportType': reportType,
      'imagePath': _legacyImagePath ?? '',
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'progressIndex': progressIndex,
      'statusLabel': statusLabel,
      'statusColor': statusColor.toARGB32(),
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
      'categoryName': categoryName,
      'subCategoryName': subCategoryName,
      'isSynced': isSynced,
      'localId': localId,
      'subCategoryId': subCategoryId,
      'visibility': visibility,
      'authorityName': authorityName,
      'createdByName': createdByName,
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    // Parse attachments list (new format) with backward compat
    final rawAttachments = json['attachments'];
    final attachments = rawAttachments is List
        ? rawAttachments
              .whereType<Map>()
              .map(
                (a) => AttachmentModel.fromJson(Map<String, dynamic>.from(a)),
              )
              .toList()
        : <AttachmentModel>[];

    return ReportModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      submittedAgo: json['submittedAgo']?.toString() ?? '',
      fullDescription: json['fullDescription']?.toString() ?? '',
      reportType: json['reportType']?.toString() ?? '',
      attachments: attachments,
      imagePath: json['imagePath']?.toString(),
      progressIndex: int.tryParse(json['progressIndex']?.toString() ?? '') ?? 0,
      statusLabel: json['statusLabel']?.toString() ?? '',
      statusColor: Color(
        int.tryParse(json['statusColor']?.toString() ?? '') ??
            const Color(0xFF2A9AF4).toARGB32(),
      ),
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0,
      locationAddress: json['locationAddress']?.toString(),
      categoryName: json['categoryName']?.toString(),
      subCategoryName: json['subCategoryName']?.toString(),
      isSynced: json['isSynced'] != false,
      localId: json['localId']?.toString(),
      subCategoryId: json['subCategoryId']?.toString(),
      visibility: json['visibility']?.toString(),
      authorityName: json['authorityName']?.toString(),
      createdByName: json['createdByName']?.toString(),
    );
  }

  factory ReportModel.fromApiJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? '';
    final statusLabel = _statusLabel(status, json['statusLabel']?.toString());
    final statusColor = _statusColor(statusLabel);

    // Parse attachments array from backend response
    final rawAttachments = json['attachments'];
    final attachments = rawAttachments is List
        ? rawAttachments
              .whereType<Map>()
              .map(
                (a) =>
                    AttachmentModel.fromApiJson(Map<String, dynamic>.from(a)),
              )
              .toList()
        : <AttachmentModel>[];

    // Fall back to legacy image extraction if no structured attachments
    final legacyImagePath = attachments.isEmpty
        ? _extractImagePath(json)
        : null;

    if (attachments.isEmpty && (legacyImagePath?.trim().isEmpty ?? true)) {
      try {
        final id = json['id'] ?? json['reportId'] ?? '(unknown)';
        print(
          'ReportModel.fromApiJson: no attachments for id: $id; keys: ${json.keys.toList()}',
        );
      } catch (_) {}
    }

    // Parse location — handle both nested object and flat fields
    final locationData = json['location'];
    double latitude;
    double longitude;
    String? locationAddress;

    if (locationData is Map) {
      latitude =
          double.tryParse(locationData['latitude']?.toString() ?? '') ?? 0;
      longitude =
          double.tryParse(locationData['longitude']?.toString() ?? '') ?? 0;
      locationAddress =
          locationData['address']?.toString() ??
          locationData['locationAddress']?.toString() ??
          json['locationAddress']?.toString() ??
          json['address']?.toString();
    } else {
      latitude = double.tryParse(json['latitude']?.toString() ?? '') ?? 0;
      longitude = double.tryParse(json['longitude']?.toString() ?? '') ?? 0;
      locationAddress =
          json['locationAddress']?.toString() ?? json['address']?.toString();
    }

    // Parse subcategory name from either string or nested object
    final subCategoryName = json['subCategory'] is String
        ? json['subCategory']?.toString()
        : json['subCategoryName']?.toString() ??
              (json['subCategory'] is Map
                  ? json['subCategory']['name']?.toString()
                  : null);
    final categoryName = json['category'] is String
        ? json['category']?.toString()
        : json['categoryName']?.toString() ??
              (json['category'] is Map
                  ? json['category']['name']?.toString()
                  : null);

    return ReportModel(
      id: json['id']?.toString() ?? json['reportId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      submittedAgo: json['submittedAgo']?.toString() ?? '',
      fullDescription:
          json['fullDescription']?.toString() ??
          json['description']?.toString() ??
          '',
      reportType:
          subCategoryName ??
          categoryName ??
          json['reportType']?.toString() ??
          '',
      attachments: attachments,
      imagePath: legacyImagePath,
      progressIndex: _statusIndex(statusLabel),
      statusLabel: statusLabel,
      statusColor: statusColor,
      latitude: latitude,
      longitude: longitude,
      locationAddress: locationAddress,
      categoryName: categoryName,
      subCategoryName: subCategoryName,
      isSynced: true,
      localId: null,
      subCategoryId:
          json['subCategoryId']?.toString() ??
          (json['subCategory'] is Map
              ? json['subCategory']['id']?.toString()
              : null),
      visibility: json['visibility']?.toString(),
      authorityName: json['authorityName']?.toString(),
      createdByName: json['createdByName']?.toString(),
    );
  }

  static String _extractImagePath(Map<String, dynamic> json) {
    const preferredKeys = [
      'imageUrl',
      'imagePath',
      'attachmentUrl',
      'attachment',
      'image',
      'images',
      'attachments',
      'media',
      'files',
      'reportImages',
      'reportAttachments',
      'fileUrl',
      'filePath',
      'url',
      'path',
      'src',
      'downloadUrl',
      'contentUrl',
      'originalUrl',
      'thumbnailUrl',
    ];

    final directKeys = [
      ...preferredKeys,
      'photo',
      'photoUrl',
      'file',
      'fileName',
    ];

    for (final key in directKeys) {
      final value = _extractStringValue(json[key]);
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return _findStringInJson(json, preferredKeys) ?? '';
  }

  static String? _extractStringValue(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      // Build full URL if it's a relative path
      if (trimmed.startsWith('/')) {
        return '${ApiConfig.baseUrl}$trimmed';
      }
      return trimmed;
    }

    if (value is List) {
      for (final item in value) {
        final v = _extractStringValue(item);
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      // Check all possible image/file path fields in order of preference
      final possibleImagePath =
          map['filePath'] ??
          map['path'] ??
          map['url'] ??
          map['fileUrl'] ??
          map['attachment'] ??
          map['imageUrl'] ??
          map['imagePath'] ??
          map['fileName'];

      if (possibleImagePath != null) {
        return _extractStringValue(possibleImagePath);
      }
      return null;
    }

    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? null : stringValue;
  }

  static String? _findStringInJson(
    dynamic value,
    List<String> preferredKeys, {
    String? currentKey,
  }) {
    if (value == null) return null;

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      for (final entry in map.entries) {
        final nested = _findStringInJson(
          entry.value,
          preferredKeys,
          currentKey: entry.key.toString(),
        );
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
      return null;
    }

    if (value is List) {
      for (final item in value) {
        final nested = _findStringInJson(
          item,
          preferredKeys,
          currentKey: currentKey,
        );
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
      return null;
    }

    final stringValue = value.toString().trim();
    if (stringValue.isEmpty) return null;

    if (currentKey != null && preferredKeys.contains(currentKey)) {
      return stringValue;
    }

    return _looksLikeImageReference(stringValue) ? stringValue : null;
  }

  static bool _looksLikeImageReference(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('file://') ||
        lower.startsWith('/') ||
        lower.startsWith('assets/') ||
        lower.startsWith('storage/') ||
        lower.startsWith('content://') ||
        lower.startsWith('blob:') ||
        RegExp(
          r'\.(png|jpe?g|gif|webp|bmp|heic|heif)(\?|#|$)',
        ).hasMatch(lower) ||
        lower.contains('/');
  }

  static String _statusLabel(String status, String? fallback) {
    if (fallback != null && fallback.trim().isNotEmpty) return fallback;

    switch (status.toLowerCase()) {
      case 'received':
      case 'submitted':
        return 'تم الاستلام';
      case 'review':
      case 'inreview':
      case 'underreview':
      case 'under review':
        return 'قيد المراجعه';
      case 'processing':
      case 'inprogress':
      case 'dispatched':
        return 'قيد المعالجه';
      case 'resolved':
      case 'completed':
        return 'تم الحل';
      case 'rejected':
      case 'declined':
      case 'canceled':
        return 'تم الرفض';
      default:
        return 'تم الاستلام';
    }
  }

  static int _statusIndex(String statusLabel) {
    switch (statusLabel) {
      case 'قيد المراجعه':
        return 1;
      case 'قيد المعالجه':
        return 2;
      case 'تم الحل':
        return 3;
      default:
        return 0;
    }
  }

  static Color _statusColor(String statusLabel) {
    switch (statusLabel) {
      case 'قيد المراجعه':
        return const Color(0xFFFFCA28);
      case 'قيد المعالجه':
        return const Color(0xFF38A0FA);
      case 'تم الحل':
        return const Color(0xFF4CAF50);
      case 'تم الرفض':
        return const Color(0xFFFF0004);
      default:
        return const Color(0xFF38A0FA);
    }
  }

  static String? extractCity(String? address) {
    if (address == null) return null;
    final normalized = address.trim();
    if (normalized.isEmpty) return null;

    final separators = ['،', ','];
    for (final separator in separators) {
      if (normalized.contains(separator)) {
        final parts = normalized
            .split(separator)
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) {
          return parts.last;
        }
      }
    }

    return normalized;
  }
}
