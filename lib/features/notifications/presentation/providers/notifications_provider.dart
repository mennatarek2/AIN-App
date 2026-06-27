import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/device_token_storage.dart';
import '../../../../core/notifications/fcm_notification_service.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../data/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_data_providers.dart';

// ─── Notification type (UI helpers) ───────────────────────────────────────────

enum NotificationType { sos, reportUpdate, system }

enum NotificationSection { today, thisWeek }

// ─── State ────────────────────────────────────────────────────────────────────

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.pageIndex = 1,
    this.hasMore = true,
    this.error,
    this.unreadCount = 0,
  });

  final List<NotificationModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final int pageIndex;
  final bool hasMore;
  final String? error;
  final int unreadCount;

  NotificationsState copyWith({
    List<NotificationModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    int? pageIndex,
    bool? hasMore,
    String? error,
    int? unreadCount,
    bool clearError = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      pageIndex: pageIndex ?? this.pageIndex,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  List<NotificationModel> itemsForSection(NotificationSection section) {
    return items.where((item) => sectionFor(item.createdAt) == section).toList();
  }

  static NotificationSection sectionFor(DateTime createdAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final createdDay = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );
    if (!createdDay.isBefore(today)) return NotificationSection.today;

    final weekAgo = today.subtract(const Duration(days: 7));
    if (!createdDay.isBefore(weekAgo)) return NotificationSection.thisWeek;

    return NotificationSection.thisWeek;
  }

  static NotificationType typeFor(NotificationModel item) {
    final text = '${item.title} ${item.body}'.toLowerCase();
    if (text.contains('sos') ||
        text.contains('طوارئ') ||
        text.contains('نداء')) {
      return NotificationType.sos;
    }
    if (text.contains('بلاغ') ||
        text.contains('report') ||
        text.contains('حالة')) {
      return NotificationType.reportUpdate;
    }
    return NotificationType.system;
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(
    this._repository,
    this._pushNotificationService,
  ) : super(const NotificationsState()) {
    _bootstrap();
  }

  final NotificationRepository _repository;
  final PushNotificationService _pushNotificationService;

  static const int _pageSize = 20;

  Future<void> _bootstrap() async {
    await _pushNotificationService.initialize();
    if (_pushNotificationService is FcmNotificationService) {
      _pushNotificationService.onMessageReceived = _handlePushReceived;
    }
  }

  Future<void> loadInitial() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _repository.fetchNotifications(pageIndex: 1, pageSize: _pageSize),
        _repository.fetchUnreadCount(),
      ]);
      if (!mounted) return;

      final items = results[0] as List<NotificationModel>;
      final unread = results[1] as int;

      state = state.copyWith(
        items: items,
        isLoading: false,
        pageIndex: 1,
        hasMore: items.length >= _pageSize,
        unreadCount: unread,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }

  Future<void> refresh() async {
    if (!mounted) return;
    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      final results = await Future.wait([
        _repository.fetchNotifications(pageIndex: 1, pageSize: _pageSize),
        _repository.fetchUnreadCount(),
      ]);
      if (!mounted) return;

      final items = results[0] as List<NotificationModel>;
      final unread = results[1] as int;

      state = state.copyWith(
        items: items,
        isRefreshing: false,
        pageIndex: 1,
        hasMore: items.length >= _pageSize,
        unreadCount: unread,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isRefreshing: false, error: _errorMessage(e));
    }
  }

  Future<void> loadMore() async {
    if (!mounted || state.isLoadingMore || !state.hasMore) return;

    final nextPage = state.pageIndex + 1;
    state = state.copyWith(isLoadingMore: true);

    try {
      final items = await _repository.fetchNotifications(
        pageIndex: nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;

      state = state.copyWith(
        items: [...state.items, ...items],
        isLoadingMore: false,
        pageIndex: nextPage,
        hasMore: items.length >= _pageSize,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      final unread = await _repository.fetchUnreadCount();
      if (!mounted) return;
      state = state.copyWith(unreadCount: unread);
    } catch (_) {
      // Non-fatal — keep cached count.
    }
  }

  Future<void> markRead(String id) async {
    final original = state.items;
    final updated = state.items
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    final wasUnread = original.any((n) => n.id == id && !n.isRead);

    state = state.copyWith(
      items: updated,
      unreadCount: wasUnread && state.unreadCount > 0
          ? state.unreadCount - 1
          : state.unreadCount,
    );

    try {
      await _repository.markAsRead(id);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(items: original);
      await refreshUnreadCount();
    }
  }

  Future<void> markAllRead() async {
    final original = state.items;
    final updated = state.items.map((n) => n.copyWith(isRead: true)).toList();

    state = state.copyWith(items: updated, unreadCount: 0);

    try {
      await _repository.markAllAsRead();
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(items: original);
      await refreshUnreadCount();
    }
  }

  // ── SOS notification (called by SignalR bridge) ────────────────────────────

  Future<void> addSOSNotification({
    required String sosId,
    required String severity,
    String? message,
    String? communityName,
  }) async {
    final label = _severityLabel(severity);
    final body = communityName != null
        ? 'نداء ($label) من مجتمع $communityName'
        : 'نداء طوارئ جديد — $label';

    final localService = _pushNotificationService;
    if (localService is LocalNotificationService) {
      await localService.showSOSAlert(
        sosId: sosId,
        severity: severity,
        message: message,
        communityName: communityName,
      );
    } else if (localService is FcmNotificationService) {
      await localService.showLocalNotification(
        title: 'نداء طوارئ',
        body: body,
        payload: 'sos:$sosId',
      );
    }

    await refresh();
  }

  Future<void> addSOSResolvedNotification({
    required String sosId,
    required String resolvedBy,
  }) async {
    final localService = _pushNotificationService;
    if (localService is LocalNotificationService) {
      await localService.showSOSResolved(
        sosId: sosId,
        resolvedBy: resolvedBy,
      );
    } else if (localService is FcmNotificationService) {
      await localService.showLocalNotification(
        title: 'تم حل نداء الطوارئ',
        body: 'تم الحل بواسطة: $resolvedBy',
        payload: 'sos:$sosId',
      );
    }

    await refresh();
  }

  Future<void> notifyReportSubmitted({
    required String reportTitle,
    required String reportType,
    String? reportId,
  }) async {
    await _pushNotificationService.showReportNotification(
      title: 'تم إرسال البلاغ بنجاح',
      body: 'تم استلام "$reportTitle" وسيتم مراجعته قريباً.',
      reportId: reportId,
    );
    await refresh();
  }

  Future<void> notifyReportStatusChanged({
    required String reportTitle,
    required String statusLabel,
    String? reportId,
  }) async {
    await _pushNotificationService.showReportNotification(
      title: 'تحديث حالة البلاغ',
      body: 'حالة "$reportTitle": $statusLabel',
      reportId: reportId,
    );
    await refresh();
  }

  void _handlePushReceived() {
    refresh();
  }

  String _severityLabel(String severity) {
    return switch (severity.toLowerCase()) {
      'high' => 'مستوى عالٍ',
      'critical' => 'حرج',
      _ => 'عادي',
    };
  }

  String _errorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

// ─── Device token manager ─────────────────────────────────────────────────────

class DeviceTokenManager {
  DeviceTokenManager(this._repository);

  final NotificationRepository _repository;

  Future<void> registerCurrentToken(FcmNotificationService fcmService) async {
    final token = await fcmService.getDeviceToken();
    if (token == null || token.isEmpty) return;
    await registerToken(token);
  }

  Future<void> registerToken(String token) async {
    if (token.isEmpty) return;

    final cached = await DeviceTokenStorage.readCachedToken();
    if (cached == token) return;

    await _repository.registerDeviceToken(
      token: token,
      platform: _platformName(),
    );
    await DeviceTokenStorage.cacheToken(token);
  }

  Future<void> unregisterCachedToken() async {
    final cached = await DeviceTokenStorage.readCachedToken();
    if (cached == null || cached.isEmpty) return;

    try {
      await _repository.deleteDeviceToken(token: cached);
    } catch (_) {
      // Logout should proceed even if backend deletion fails.
    }

    await DeviceTokenStorage.clearCachedToken();
  }

  String _platformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

enum PushNotificationMode { local, fcm }

const _pushNotificationMode = PushNotificationMode.fcm;

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  switch (_pushNotificationMode) {
    case PushNotificationMode.fcm:
      return FcmNotificationService();
    case PushNotificationMode.local:
      return LocalNotificationService();
  }
});

final deviceTokenManagerProvider = Provider<DeviceTokenManager>((ref) {
  return DeviceTokenManager(ref.watch(notificationRepositoryProvider));
});

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
      return NotificationsNotifier(
        ref.watch(notificationRepositoryProvider),
        ref.watch(pushNotificationServiceProvider),
      );
    });

/// Convenience provider for unread count — used by the notification bell badge.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});

/// Backward-compatible alias for community SOS filter page.
typedef NotificationItem = NotificationModel;
