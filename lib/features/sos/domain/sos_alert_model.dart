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

  factory SosAlertModel.fromApiJson(Map<String, dynamic> json) {
    return SosAlertModel(
      id: json['id']?.toString() ?? '',
      communityId: json['communityId']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0,
      severity: json['severity']?.toString() ?? '',
      message: json['message']?.toString(),
      accuracyMeters: int.tryParse(json['accuracyMeters']?.toString() ?? ''),
      durationMinutes: int.tryParse(json['durationMinutes']?.toString() ?? ''),
      isActive: json['isActive'] as bool?,
    );
  }
}
