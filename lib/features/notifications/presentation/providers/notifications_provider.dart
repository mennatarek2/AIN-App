import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/notifications/fcm_notification_service.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../../../../core/notifications/push_notification_service.dart';

// ─── Notification type ────────────────────────────────────────────────────────

enum NotificationType { sos, reportUpdate, system }

enum NotificationSection { today, thisWeek }

// ─── Notification model ───────────────────────────────────────────────────────

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.text,
    required this.section,
    this.highlighted = false,
    this.isRead = false,
    this.type = NotificationType.system,
    this.relatedId,
    this.createdAt,
  });

  final String id;
  final String text;
  final NotificationSection section;
  final bool highlighted;
  final bool isRead;
  final NotificationType type;
  final String? relatedId; // sosAlertId or reportId
  final DateTime? createdAt;

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      text: text,
      section: section,
      highlighted: highlighted,
      isRead: isRead ?? this.isRead,
      type: type,
      relatedId: relatedId,
      createdAt: createdAt,
    );
  }
}

// ─── State ────────────────────────────────────────────────────────────────────

class NotificationsState {
  const NotificationsState({required this.items});

  final List<NotificationItem> items;

  List<NotificationItem> itemsForSection(NotificationSection section) {
    return items.where((item) => item.section == section).toList();
  }

  int get unreadCount => items.where((n) => !n.isRead).length;
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this._pushNotificationService)
    : super(const NotificationsState(items: _mockItems)) {
    _bootstrap();
  }

  final PushNotificationService _pushNotificationService;

  static const _cacheKey = 'notifications_cache_v2';

  // ── Mock seed data ─────────────────────────────────────────────────────────

  static const List<NotificationItem> _mockItems = [
    NotificationItem(
      id: 'n1',
      text: 'شكراً لك! تم استلام بلاغك "حادث سير" نراجع التفاصيل الآن',
      section: NotificationSection.today,
      highlighted: true,
      type: NotificationType.reportUpdate,
    ),
    NotificationItem(
      id: 'n2',
      text: 'بلاغك عن "مشاكل كهربية" تغير إلى حالة قيد المعالجة',
      section: NotificationSection.today,
      highlighted: true,
      type: NotificationType.reportUpdate,
    ),
    NotificationItem(
      id: 'n3',
      text: 'قام 5 أشخاص بالتفاعل علي البلاغ الخاص بك',
      section: NotificationSection.today,
      highlighted: true,
      type: NotificationType.reportUpdate,
    ),
    NotificationItem(
      id: 'n4',
      text: 'هل من بلاغ عن طرق متضررة بسبب المطر؟',
      section: NotificationSection.thisWeek,
      type: NotificationType.system,
    ),
    NotificationItem(
      id: 'n5',
      text: 'أحسنت! ربحت 10 نقاط لإرسال بلاغك الجديد بنجاح.',
      section: NotificationSection.thisWeek,
      type: NotificationType.system,
    ),
    NotificationItem(
      id: 'n6',
      text: 'تم رفض البلاغ. يرجى إعادة إرساله مع صورة أكثر دقة',
      section: NotificationSection.thisWeek,
      type: NotificationType.reportUpdate,
    ),
    NotificationItem(
      id: 'n7',
      text: 'تم إنجاز المهمة! تم حل بلاغك عن الحفرة في "اسم الشارع"',
      section: NotificationSection.thisWeek,
      type: NotificationType.reportUpdate,
    ),
  ];

  // ── Bootstrap ──────────────────────────────────────────────────────────────

  Future<void> _bootstrap() async {
    await _pushNotificationService.initialize();
    await _loadPersistedItems();
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

    final item = NotificationItem(
      id: 'sos-$sosId-${DateTime.now().microsecondsSinceEpoch}',
      text: body,
      section: NotificationSection.today,
      highlighted: true,
      isRead: false,
      type: NotificationType.sos,
      relatedId: sosId,
      createdAt: DateTime.now(),
    );

    await _addNotification(item);

    // Show local system notification
    final localService = _pushNotificationService;
    if (localService is LocalNotificationService) {
      await localService.showSOSAlert(
        sosId: sosId,
        severity: severity,
        message: message,
        communityName: communityName,
      );
    }
  }

  Future<void> addSOSResolvedNotification({
    required String sosId,
    required String resolvedBy,
  }) async {
    final item = NotificationItem(
      id: 'sos-resolved-$sosId',
      text: 'تم حل نداء الطوارئ بواسطة: $resolvedBy',
      section: NotificationSection.today,
      highlighted: false,
      isRead: false,
      type: NotificationType.sos,
      relatedId: sosId,
      createdAt: DateTime.now(),
    );

    await _addNotification(item);

    final localService = _pushNotificationService;
    if (localService is LocalNotificationService) {
      await localService.showSOSResolved(
        sosId: sosId,
        resolvedBy: resolvedBy,
      );
    }
  }

  // ── Report notifications ───────────────────────────────────────────────────

  Future<void> notifyReportSubmitted({
    required String reportTitle,
    required String reportType,
    String? reportId,
  }) async {
    final item = NotificationItem(
      id: 'n-${DateTime.now().microsecondsSinceEpoch}',
      text: 'تم استلام بلاغ "$reportType" بعنوان "$reportTitle"',
      section: NotificationSection.today,
      highlighted: true,
      isRead: false,
      type: NotificationType.reportUpdate,
      relatedId: reportId,
      createdAt: DateTime.now(),
    );

    await _addNotification(item);

    await _pushNotificationService.showReportNotification(
      title: 'تم إرسال البلاغ بنجاح',
      body: 'تم استلام "$reportTitle" وسيتم مراجعته قريباً.',
      reportId: reportId,
    );
  }

  Future<void> notifyReportStatusChanged({
    required String reportTitle,
    required String statusLabel,
    String? reportId,
  }) async {
    final item = NotificationItem(
      id: 'n-${DateTime.now().microsecondsSinceEpoch}',
      text: 'تم تحديث حالة "$reportTitle" إلى "$statusLabel"',
      section: NotificationSection.today,
      highlighted: true,
      isRead: false,
      type: NotificationType.reportUpdate,
      relatedId: reportId,
      createdAt: DateTime.now(),
    );

    await _addNotification(item);

    await _pushNotificationService.showReportNotification(
      title: 'تحديث حالة البلاغ',
      body: 'حالة "$reportTitle": $statusLabel',
      reportId: reportId,
    );
  }

  // ── Read management ────────────────────────────────────────────────────────

  void markRead(String id) {
    state = NotificationsState(
      items: state.items.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
    );
  }

  void markAllRead() {
    state = NotificationsState(
      items: state.items.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }

  void clearAll() {
    state = const NotificationsState(items: []);
    _persistItems([]);
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  Future<void> _addNotification(NotificationItem item) async {
    if (!mounted) return;
    state = NotificationsState(items: [item, ...state.items]);
    await _persistItems(state.items);
  }

  Future<void> _loadPersistedItems() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;

    final rawJson = prefs.getString(_cacheKey);
    if (rawJson == null || rawJson.isEmpty) {
      await _persistItems(state.items);
      return;
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return;

      final items = decoded
          .whereType<Map>()
          .map(
            (item) => NotificationItem(
              id: item['id']?.toString() ?? '',
              text: item['text']?.toString() ?? '',
              section: _sectionFromString(item['section']?.toString()),
              highlighted: item['highlighted'] == true,
              isRead: item['isRead'] == true,
              type: _typeFromString(item['type']?.toString()),
              relatedId: item['relatedId']?.toString(),
            ),
          )
          .where((item) => item.id.isNotEmpty && item.text.isNotEmpty)
          .toList();

      if (items.isEmpty) return;
      if (!mounted) return;
      state = NotificationsState(items: items);
    } catch (_) {
      // Corrupted cache — keep seeded fallback.
    }
  }

  Future<void> _persistItems(List<NotificationItem> items) async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;

    final payload = items
        .map(
          (item) => {
            'id': item.id,
            'text': item.text,
            'section': item.section.name,
            'highlighted': item.highlighted,
            'isRead': item.isRead,
            'type': item.type.name,
            if (item.relatedId != null) 'relatedId': item.relatedId,
          },
        )
        .toList();

    await prefs.setString(_cacheKey, jsonEncode(payload));
  }

  NotificationSection _sectionFromString(String? value) {
    return NotificationSection.values.firstWhere(
      (section) => section.name == value,
      orElse: () => NotificationSection.thisWeek,
    );
  }

  NotificationType _typeFromString(String? value) {
    return NotificationType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => NotificationType.system,
    );
  }

  String _severityLabel(String severity) {
    return switch (severity.toLowerCase()) {
      'high' => 'مستوى عالٍ',
      'critical' => 'حرج',
      _ => 'عادي',
    };
  }

  Future<SharedPreferences?> _safeGetPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

enum PushNotificationMode { local, fcm }

const _pushNotificationMode = PushNotificationMode.local;

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

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
      return NotificationsNotifier(ref.watch(pushNotificationServiceProvider));
    });

/// Convenience provider for unread count — used by the notification bell badge.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});
