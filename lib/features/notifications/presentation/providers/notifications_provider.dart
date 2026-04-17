import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/notifications/local_notification_service.dart';

enum NotificationSection { today, thisWeek }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.text,
    required this.section,
    this.highlighted = false,
  });

  final String id;
  final String text;
  final NotificationSection section;
  final bool highlighted;
}

class NotificationsState {
  const NotificationsState({required this.items});

  final List<NotificationItem> items;

  List<NotificationItem> itemsForSection(NotificationSection section) {
    return items.where((item) => item.section == section).toList();
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this._localNotificationService)
    : super(const NotificationsState(items: _mockItems)) {
    _bootstrap();
  }

  final LocalNotificationService _localNotificationService;

  static const _cacheKey = 'notifications_cache_v1';

  static const List<NotificationItem> _mockItems = [
    NotificationItem(
      id: 'n1',
      text: 'شكراً لك! تم استلام بلاغك "حادث سير" نراجع التفاصيل الآن',
      section: NotificationSection.today,
      highlighted: true,
    ),
    NotificationItem(
      id: 'n2',
      text: 'بلاغك عن "مشاكل كهربية" تغير إلى حالة قيد المعالجة',
      section: NotificationSection.today,
      highlighted: true,
    ),
    NotificationItem(
      id: 'n3',
      text: 'قام 5 أشخاص بالتفاعل علي البلاغ الخاص بك',
      section: NotificationSection.today,
      highlighted: true,
    ),
    NotificationItem(
      id: 'n4',
      text: 'هل من بلاغ عن طرق متضررة بسبب المطر؟',
      section: NotificationSection.thisWeek,
    ),
    NotificationItem(
      id: 'n5',
      text: 'أحسنت! ربحت 10 نقاط لإرسال بلاغك الجديد بنجاح.',
      section: NotificationSection.thisWeek,
    ),
    NotificationItem(
      id: 'n6',
      text: 'تم رفض البلاغ. يرجى إعادة إرساله مع صورة أكثر دقة',
      section: NotificationSection.thisWeek,
    ),
    NotificationItem(
      id: 'n7',
      text: 'تم إنجاز المهمة! تم حل بلاغك عن الحفرة في "اسم الشارع"',
      section: NotificationSection.thisWeek,
    ),
  ];

  Future<void> _bootstrap() async {
    await _localNotificationService.initialize();
    await _loadPersistedItems();
  }

  Future<void> notifyReportSubmitted({
    required String reportTitle,
    required String reportType,
  }) async {
    final item = NotificationItem(
      id: 'n-${DateTime.now().microsecondsSinceEpoch}',
      text: 'تم استلام بلاغ "$reportType" بعنوان "$reportTitle"',
      section: NotificationSection.today,
      highlighted: true,
    );

    await _addNotification(item);

    await _localNotificationService.showReportNotification(
      title: 'تم إرسال البلاغ بنجاح',
      body: 'تم استلام "$reportTitle" وسيتم مراجعته قريباً.',
    );
  }

  Future<void> notifyReportStatusChanged({
    required String reportTitle,
    required String statusLabel,
  }) async {
    final item = NotificationItem(
      id: 'n-${DateTime.now().microsecondsSinceEpoch}',
      text: 'تم تحديث حالة "$reportTitle" إلى "$statusLabel"',
      section: NotificationSection.today,
      highlighted: true,
    );

    await _addNotification(item);

    await _localNotificationService.showReportNotification(
      title: 'تحديث حالة البلاغ',
      body: 'حالة "$reportTitle": $statusLabel',
    );
  }

  Future<void> _addNotification(NotificationItem item) async {
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
            ),
          )
          .where((item) => item.id.isNotEmpty && item.text.isNotEmpty)
          .toList();

      if (items.isEmpty) return;
      if (!mounted) return;
      state = NotificationsState(items: items);
    } catch (_) {
      // If cache is corrupted, fallback to in-memory defaults.
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

  Future<SharedPreferences?> _safeGetPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }
}

final localNotificationServiceProvider = Provider<LocalNotificationService>((
  ref,
) {
  return LocalNotificationService();
});

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
      return NotificationsNotifier(ref.watch(localNotificationServiceProvider));
    });
