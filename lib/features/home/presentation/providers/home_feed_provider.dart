import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/comments_bottom_sheet.dart';
import '../widgets/report_card.dart';

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
            },
          )
          .toList(),
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
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
      imageUrl:
          json['imageUrl']?.toString() ?? 'assets/images/report_image.png',
      tags: parsedTags,
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0,
      locationAddress: json['locationAddress']?.toString(),
    );
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
  HomeFeedNotifier() : super(_initialState()) {
    _loadPersistedData();
  }

  static const _reportsCacheKey = 'home_feed_reports_cache_v1';
  static const _commentsCacheKey = 'home_feed_comments_cache_v1';

  static HomeFeedState _initialState() {
    return HomeFeedState(
      reports: [
        HomeReport(
          id: 'report-1',
          username: 'Ahmed',
          timeAgo: '20 دقيقة',
          title: 'حفرة في الطريق تهدد سلامة المشاة والمركبات',
          imageUrl: 'assets/images/report_image.png',
          latitude: 30.0452,
          longitude: 31.2338,
          locationAddress: 'Nasr City, Cairo',
          tags: [
            ReportTag(
              label: 'مدينة نصر، القاهرة',
              dotColor: Colors.red,
              showPin: true,
            ),
            ReportTag(label: 'قيد المراجعة', dotColor: Colors.amber),
            ReportTag(label: 'مشاكل الطرق', dotColor: Colors.grey),
          ],
        ),
        HomeReport(
          id: 'report-2',
          username: 'Amr M',
          timeAgo: '30 دقيقة',
          title: 'يوجد حريق في الشارع، مع وجود نيران ودخان كثيف',
          imageUrl: 'assets/images/report_image.png',
          latitude: 30.0383,
          longitude: 31.2211,
          locationAddress: 'Maadi, Cairo',
          tags: [
            ReportTag(label: 'القاهرة', dotColor: Colors.red, showPin: true),
            ReportTag(label: 'تم الإبلاغ', dotColor: Colors.green),
            ReportTag(label: 'سلامة', dotColor: Colors.grey),
          ],
        ),
      ],
      commentsByReport: {
        'report-1': [
          CommentItemData(
            id: 'c1',
            username: 'ايمان عصام',
            text: 'تم إرسال بلاغ مشابه اليوم. نحتاج تدخل سريع.',
            timeAgo: 'منذ 15 دقيقة',
            likesCount: 4,
          ),
          CommentItemData(
            id: 'c2',
            username: 'عبدالرحمن سيد',
            text: 'الطريق في هذه المنطقة أصبح خطير خاصة ليلا.',
            timeAgo: 'منذ 32 دقيقة',
            likesCount: 2,
          ),
        ],
      },
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

  void addReport({
    required String title,
    required String category,
    required String reportType,
    required String visibility,
    required double latitude,
    required double longitude,
    String? locationAddress,
  }) {
    final reportId = DateTime.now().microsecondsSinceEpoch.toString();
    final newReport = HomeReport(
      id: reportId,
      username: 'أنت',
      timeAgo: 'الآن',
      title: title,
      imageUrl: 'assets/images/report_image.png',
      latitude: latitude,
      longitude: longitude,
      locationAddress: locationAddress,
      tags: [
        ReportTag(
          label:
              locationAddress ??
              '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
          dotColor: Colors.red,
          showPin: true,
        ),
        ReportTag(label: 'تم الإرسال', dotColor: Colors.green),
        ReportTag(label: category, dotColor: Colors.grey),
        ReportTag(
          label: '$reportType • $visibility',
          dotColor: Colors.blueGrey,
        ),
      ],
    );

    state = state.copyWith(
      reports: [newReport, ...state.reports],
      commentsByReport: {...state.commentsByReport, reportId: const []},
    );
    _persistCurrentData();
  }

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
}

final homeFeedProvider = StateNotifierProvider<HomeFeedNotifier, HomeFeedState>(
  (ref) {
    return HomeFeedNotifier();
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
