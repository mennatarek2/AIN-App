enum NotificationType {
  sosTriggered(0),
  sosResolved(1),
  sosCancelled(2),
  sosFalseAlarm(3),
  sosExpired(4),
  reportStatusChanged(10),
  reportAssigned(11),
  reportCommented(12),
  communityJoined(20),
  communityJoinRequested(21),
  communityJoinApproved(22),
  communityJoinRejected(23),
  communityMemberRemoved(24),
  communityLocationReminder(25),
  communityInvited(26),
  trustPointsChanged(30),
  accountVerified(31),
  passwordChanged(32);

  const NotificationType(this.value);
  final int value;

  static NotificationType fromInt(int v) =>
      values.firstWhere((e) => e.value == v, orElse: () => sosTriggered);

  bool get isSos => value <= 4;
  bool get isCommunity => value >= 20 && value <= 26;
  bool get isReport => value >= 10 && value <= 12;
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.actionUrl,
    this.resourceId,
    this.resourceType,
    required this.isRead,
    required this.priority,
    required this.createdAt,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? actionUrl;
  final String? resourceId;
  final String? resourceType;
  final bool isRead;
  final int priority;
  final DateTime createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: NotificationType.fromInt(
        json['type'] is int
            ? json['type'] as int
            : int.tryParse(json['type']?.toString() ?? '') ?? 0,
      ),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      actionUrl: json['actionUrl'] as String?,
      resourceId: json['resourceId'] as String?,
      resourceType: json['resourceType'] as String?,
      isRead: json['isRead'] == true,
      priority: json['priority'] is int
          ? json['priority'] as int
          : int.tryParse(json['priority']?.toString() ?? '') ?? 1,
      createdAt: _parseDateTime(json['createdAtUtc'] ?? json['createdAt']),
    );
  }

  /// Backward-compatible alias used by existing data layer.
  factory NotificationModel.fromApiJson(Map<String, dynamic> json) =>
      NotificationModel.fromJson(json);

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      actionUrl: actionUrl,
      resourceId: resourceId,
      resourceType: resourceType,
      isRead: isRead ?? this.isRead,
      priority: priority,
      createdAt: createdAt,
    );
  }

  bool get isCritical => priority >= 3;
  bool get isHigh => priority >= 2;

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
