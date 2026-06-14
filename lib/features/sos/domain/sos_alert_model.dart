class SosAlertModel {
  const SosAlertModel({
    required this.id,
    required this.communityId,
    required this.latitude,
    required this.longitude,
    required this.severity,
    this.message,
    this.accuracyMeters,
    this.durationMinutes,
    this.isActive,
    this.status,
    this.triggeredAt,
    this.resolvedBy,
    this.cancelledAt,
  });

  final String id;
  final String communityId;
  final double latitude;
  final double longitude;
  final String severity;
  final String? message;
  final int? accuracyMeters;
  final int? durationMinutes;
  final bool? isActive;
  final String? status;       // Active | Resolved | Cancelled | FalseAlarm
  final DateTime? triggeredAt;
  final String? resolvedBy;
  final DateTime? cancelledAt;

  factory SosAlertModel.fromApiJson(Map<String, dynamic> json) {
    // The API now returns integer status (0=Active,1=Resolved,2=Cancelled,3=FalseAlarm)
    // and integer severity (0=Low,1=Standard,2=High,3=Critical).
    // We convert to readable strings for the UI.
    final rawStatus = json['status'];
    final statusStr = rawStatus is int
        ? const ['Active', 'Resolved', 'Cancelled', 'FalseAlarm'][rawStatus.clamp(0, 3)]
        : rawStatus?.toString() ?? 'Active';

    final rawSeverity = json['severity'];
    final severityStr = rawSeverity is int
        ? const ['Low', 'Standard', 'High', 'Critical'][rawSeverity.clamp(0, 3)]
        : rawSeverity?.toString() ?? 'Standard';

    // triggeredAt may come as createdAtUtc in newer responses
    final triggeredRaw = json['triggeredAt'] ?? json['createdAtUtc'];

    return SosAlertModel(
      id: json['id']?.toString() ?? '',
      communityId: json['communityId']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      severity: severityStr,
      message: json['message']?.toString(),
      accuracyMeters: int.tryParse(json['accuracyMeters']?.toString() ?? ''),
      durationMinutes: int.tryParse(json['durationMinutes']?.toString() ?? ''),
      isActive: json['isActive'] as bool? ?? statusStr == 'Active',
      status: statusStr,
      triggeredAt: triggeredRaw != null
          ? DateTime.tryParse(triggeredRaw.toString())
          : null,
      resolvedBy: json['resolvedBy']?.toString(),
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'].toString())
          : null,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  SosAlertModel copyWith({
    String? id,
    String? communityId,
    double? latitude,
    double? longitude,
    String? severity,
    String? message,
    int? accuracyMeters,
    int? durationMinutes,
    bool? isActive,
    String? status,
    DateTime? triggeredAt,
    String? resolvedBy,
    DateTime? cancelledAt,
  }) {
    return SosAlertModel(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      severity: severity ?? this.severity,
      message: message ?? this.message,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}
