/// Lightweight data class representing a single map pin returned by
/// `GET /api/Reports/map-data`.
class ReportMapPin {
  const ReportMapPin({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.status,
    required this.categoryName,
    this.locationName,
    this.submittedAt,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String title;

  /// Raw status string from API: "UnderReview" | "Dispatched" | "Resolved" | "Rejected"
  final String status;
  final String categoryName;
  final String? locationName;
  final DateTime? submittedAt;

  /// Human-readable time-ago string (Arabic).
  String get timeAgo {
    if (submittedAt == null) return '';
    final diff = DateTime.now().difference(submittedAt!);
    if (diff.inDays > 30) return 'منذ أكثر من شهر';
    if (diff.inDays >= 1) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours >= 1) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes >= 1) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }

  factory ReportMapPin.fromJson(Map<String, dynamic> json) {
    return ReportMapPin(
      id: (json['id'] ?? json['reportId'] ?? '').toString(),
      latitude: _parseDouble(json['latitude'] ?? json['lat']),
      longitude: _parseDouble(json['longitude'] ?? json['lng'] ?? json['lon']),
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      categoryName: (json['categoryName'] ?? json['category'] ?? '').toString(),
      locationName: json['locationName']?.toString() ?? json['address']?.toString(),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ReportMapPin && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
