import 'dart:async';
import 'dart:convert';

import 'package:ain_graduation_project/core/network/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/comments_bottom_sheet.dart';
import '../widgets/report_card.dart';
import '../../../reports/domain/report_model.dart';
import '../../../reports/domain/repositories/report_repository.dart';
import '../../../reports/presentation/providers/report_data_providers.dart';

class HomeReport {
  const HomeReport({
    required this.id,
    required this.username,
    required this.timeAgo,
    required this.title,
    required this.imageUrl,
    required this.tags,
    required this.latitude,
    required this.longitude,
    this.locationAddress,
    this.createdByName,
  });

  final String id;
  final String username;
  final String timeAgo;
  final String title;
  final String imageUrl;
  final List<ReportTag> tags;
  final double latitude;
  final double longitude;
  final String? locationAddress;
  /// Name of the report creator — null for anonymous reports.
  final String? createdByName;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'timeAgo': timeAgo,
      'title': title,
      'imageUrl': imageUrl,
      'tags': tags
          .map(
            (tag) => {
              'label': tag.label,
              'dotColor': tag.dotColor.toARGB32(),
              'showPin': tag.showPin,
              'showDot': tag.showDot,
            },
          )
          .toList(),
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
      'createdByName': createdByName,
    };
  }

  factory HomeReport.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final parsedTags = rawTags is List
        ? rawTags
              .whereType<Map>()
              .map(
                (tag) => ReportTag(
                  label: tag['label']?.toString() ?? '',
                  dotColor: Color(
                    int.tryParse(tag['dotColor']?.toString() ?? '') ??
                        const Color(0xFF9E9E9E).toARGB32(),
                  ),
                  showPin: tag['showPin'] == true,
                  showDot: tag['showDot'] != false,
                ),
              )
              .where((tag) => tag.label.isNotEmpty)
              .toList()
        : <ReportTag>[];

    return HomeReport(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      timeAgo: json['timeAgo']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: _extractImageUrl(json),
      tags: parsedTags,
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0,
      locationAddress: json['locationAddress']?.toString(),
      createdByName: json['createdByName']?.toString(),
    );
  }

  static String _extractImageUrl(Map<String, dynamic> json) {
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
      'photo',
      'photoUrl',
      'file',
      'fileName',
    ];

    for (final key in preferredKeys) {
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
}

class HomeFeedState {
  const HomeFeedState({
    required this.reports,
    required this.commentsByReport,
    required this.searchQuery,
    required this.filterEnabled,
  });

  final List<HomeReport> reports;
  final Map<String, List<CommentItemData>> commentsByReport;
  final String searchQuery;
  final bool filterEnabled;

  HomeFeedState copyWith({
    List<HomeReport>? reports,
    Map<String, List<CommentItemData>>? commentsByReport,
    String? searchQuery,
    bool? filterEnabled,
  }) {
    return HomeFeedState(
      reports: reports ?? this.reports,
      commentsByReport: commentsByReport ?? this.commentsByReport,
      searchQuery: searchQuery ?? this.searchQuery,
      filterEnabled: filterEnabled ?? this.filterEnabled,
    );
  }
}

class HomeFeedNotifier extends StateNotifier<HomeFeedState> {
  HomeFeedNotifier(this._reportRepository) : super(_initialState()) {
    unawaited(_bootstrap());
  }

  final ReportRepository _reportRepository;

  static const _reportsCacheKey = 'home_feed_reports_cache_v2';
  static const _commentsCacheKey = 'home_feed_comments_cache_v2';

  Future<void> _bootstrap() async {
    await _loadPersistedData();
    await _loadRemoteReports();
  }

  static HomeFeedState _initialState() {
    return HomeFeedState(
      reports: const [],
      commentsByReport: const {},
      searchQuery: '',
      filterEnabled: false,
    );
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value.trim());
  }

  void toggleFilter() {
    state = state.copyWith(filterEnabled: !state.filterEnabled);
  }

  List<CommentItemData> commentsForReport(String reportId) {
    return List<CommentItemData>.from(
      state.commentsByReport[reportId] ?? const [],
    );
  }

  void toggleLike(String reportId, String commentId) {
    final currentList = state.commentsByReport[reportId];
    if (currentList == null) return;

    final index = currentList.indexWhere((comment) => comment.id == commentId);
    if (index == -1) return;

    final updatedComment = currentList[index].copyWith(
      isLiked: !currentList[index].isLiked,
      likesCount: currentList[index].isLiked
          ? currentList[index].likesCount - 1
          : currentList[index].likesCount + 1,
    );

    final updatedComments = List<CommentItemData>.from(currentList);
    updatedComments[index] = updatedComment;

    state = state.copyWith(
      commentsByReport: {...state.commentsByReport, reportId: updatedComments},
    );
    _persistCurrentData();
  }

  void addComment(String reportId, String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final updatedComments = List<CommentItemData>.from(
      state.commentsByReport[reportId] ?? const [],
    );
    updatedComments.insert(
      0,
      CommentItemData(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        username: 'أنت',
        text: trimmedText,
        timeAgo: 'الآن',
      ),
    );

    state = state.copyWith(
      commentsByReport: {...state.commentsByReport, reportId: updatedComments},
    );
    _persistCurrentData();
  }

  Future<void> refreshReportsFromApi() async {
    await _loadRemoteReports();
  }

  void addReport({
    required String title,
    required String category,
    required String reportType,
    required String visibility,
    required double latitude,
    required double longitude,
    String? locationAddress,
    String? imagePath,
  }) {}

  void _persistCurrentData() {
    unawaited(_persistData(state.reports, state.commentsByReport));
  }

  Future<void> _loadPersistedData() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;

    final rawReports = prefs.getString(_reportsCacheKey);
    final rawComments = prefs.getString(_commentsCacheKey);

    if ((rawReports == null || rawReports.isEmpty) &&
        (rawComments == null || rawComments.isEmpty)) {
      await _persistData(state.reports, state.commentsByReport);
      return;
    }

    List<HomeReport> persistedReports = state.reports;
    Map<String, List<CommentItemData>> persistedComments =
        state.commentsByReport;

    try {
      if (rawReports != null && rawReports.isNotEmpty) {
        final decoded = jsonDecode(rawReports);
        if (decoded is List) {
          final reports = decoded
              .whereType<Map>()
              .map(
                (item) => HomeReport.fromJson(Map<String, dynamic>.from(item)),
              )
              .where(
                (report) => report.id.isNotEmpty && report.title.isNotEmpty,
              )
              .toList();
          if (reports.isNotEmpty) {
            persistedReports = reports;
          }
        }
      }

      if (rawComments != null && rawComments.isNotEmpty) {
        final decoded = jsonDecode(rawComments);
        if (decoded is Map) {
          final comments = <String, List<CommentItemData>>{};

          decoded.forEach((key, value) {
            if (key is! String || value is! List) return;

            final items = value
                .whereType<Map>()
                .map(
                  (item) => CommentItemData(
                    id: item['id']?.toString() ?? '',
                    username: item['username']?.toString() ?? '',
                    text: item['text']?.toString() ?? '',
                    timeAgo: item['timeAgo']?.toString() ?? '',
                    likesCount:
                        int.tryParse(item['likesCount']?.toString() ?? '') ?? 0,
                    isLiked: item['isLiked'] == true,
                  ),
                )
                .where((item) => item.id.isNotEmpty && item.text.isNotEmpty)
                .toList();

            comments[key] = items;
          });

          persistedComments = comments;
        }
      }

      if (!mounted) return;
      state = state.copyWith(
        reports: persistedReports,
        commentsByReport: persistedComments,
      );
    } catch (_) {
      // Keep defaults if persisted payload is malformed.
    }
  }

  Future<void> _loadRemoteReports() async {
    try {
      final remote = await _reportRepository.fetchPublicReports();
      if (!mounted) return;

      final mapped = remote
          .map(
            (report) {
              // Determine display name: use createdByName for non-anonymous,
              // 'مجهول' for anonymous, 'مستخدم' as default fallback.
              final String username;
              final visibility = report.visibility?.toLowerCase();
              if (visibility == 'anonymous') {
                username = 'مجهول';
              } else if (report.createdByName != null &&
                  report.createdByName!.trim().isNotEmpty) {
                username = report.createdByName!;
              } else {
                username = 'مستخدم';
              }

              return HomeReport(
                id: report.id,
                username: username,
                createdByName: report.createdByName,
                timeAgo: _formatRelativeArabic(report.submittedAgo),
                title: report.title,
                // imagePath is now a computed getter — returns first attachment
                // URL or falls back to legacy path. No guessing needed.
                imageUrl: report.imagePath,
                latitude: report.latitude,
                longitude: report.longitude,
                locationAddress: report.locationAddress,
                tags: [
                  ReportTag(
                    label: report.reportType.isNotEmpty
                        ? report.reportType
                        : 'بلاغ',
                    dotColor: Colors.grey,
                    showDot: false,
                  ),
                  ReportTag(
                    label: report.statusLabel,
                    dotColor: report.statusColor,
                  ),
                  ReportTag(
                    label: _getLocationName(
                      report.latitude,
                      report.longitude,
                      report.locationAddress,
                    ),
                    dotColor: Colors.red,
                    showPin: true,
                  ),
                ],
              );
            },
          )
          .toList();

      // Debug: print image paths returned from API
      for (final r in mapped) {
        try {
          print(
            'HomeFeed report loaded -> id: ${r.id}, imageUrl: "${r.imageUrl}"',
          );
        } catch (_) {}
      }

      state = state.copyWith(reports: mapped);
      _persistCurrentData();
    } catch (_) {
      // Keep cached data on failure.
    }
  }

  Future<void> _persistData(
    List<HomeReport> reports,
    Map<String, List<CommentItemData>> commentsByReport,
  ) async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;

    final reportsPayload = reports.map((report) => report.toJson()).toList();
    final commentsPayload = commentsByReport.map(
      (reportId, comments) => MapEntry(
        reportId,
        comments
            .map(
              (comment) => {
                'id': comment.id,
                'username': comment.username,
                'text': comment.text,
                'timeAgo': comment.timeAgo,
                'likesCount': comment.likesCount,
                'isLiked': comment.isLiked,
              },
            )
            .toList(),
      ),
    );

    await prefs.setString(_reportsCacheKey, jsonEncode(reportsPayload));
    await prefs.setString(_commentsCacheKey, jsonEncode(commentsPayload));
  }

  Future<SharedPreferences?> _safeGetPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  String _cityLabel(String? address) {
    return ReportModel.extractCity(address) ?? 'غير محدد';
  }

  /// Formats relative time in Arabic
  String _formatRelativeArabic(String timeAgoString) {
    if (timeAgoString.isEmpty) return 'الآن';
    // API provides pre-formatted Arabic time strings
    return timeAgoString;
  }

  /// Gets location display name from coordinates or address
  String _getLocationName(double latitude, double longitude, String? address) {
    // Prefer address if available, otherwise show coordinates
    if (address != null && address.trim().isNotEmpty) {
      return _cityLabel(address);
    }
    // Fallback to formatted coordinates
    if (latitude != 0 || longitude != 0) {
      final lat = latitude.toStringAsFixed(2);
      final lng = longitude.toStringAsFixed(2);
      return '$lat°, $lng°';
    }
    return 'غير محدد';
  }
}

final homeFeedProvider = StateNotifierProvider<HomeFeedNotifier, HomeFeedState>(
  (ref) {
    final repository = ref.watch(reportRepositoryProvider);
    return HomeFeedNotifier(repository);
  },
);

final filteredHomeReportsProvider = Provider<List<HomeReport>>((ref) {
  final state = ref.watch(homeFeedProvider);
  final query = state.searchQuery;

  if (query.isEmpty) {
    return state.reports;
  }

  return state.reports
      .where(
        (report) =>
            report.title.contains(query) || report.username.contains(query),
      )
      .toList();
});
