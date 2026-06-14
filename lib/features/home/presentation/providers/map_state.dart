import '../../domain/report_map_pin.dart';

/// Immutable state for the interactive map screen.
class MapState {
  const MapState({
    this.pins = const [],
    this.selectedPin,
    this.isLoading = false,
    this.error,
    this.filterCategoryId,
    this.filterStatus,
    this.userLatitude,
    this.userLongitude,
  });

  final List<ReportMapPin> pins;
  final ReportMapPin? selectedPin;
  final bool isLoading;
  final String? error;

  /// Active category filter (null = all categories).
  final String? filterCategoryId;

  /// Active status filter (null = all statuses).
  final String? filterStatus;

  /// User's current location — non-null after a successful My Location request.
  final double? userLatitude;
  final double? userLongitude;

  bool get hasUserLocation => userLatitude != null && userLongitude != null;
  bool get hasActiveFilter =>
      filterCategoryId != null || filterStatus != null;

  MapState copyWith({
    List<ReportMapPin>? pins,
    ReportMapPin? Function()? selectedPin,
    bool? isLoading,
    String? Function()? error,
    String? Function()? filterCategoryId,
    String? Function()? filterStatus,
    double? Function()? userLatitude,
    double? Function()? userLongitude,
  }) {
    return MapState(
      pins: pins ?? this.pins,
      selectedPin: selectedPin != null ? selectedPin() : this.selectedPin,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
      filterCategoryId: filterCategoryId != null
          ? filterCategoryId()
          : this.filterCategoryId,
      filterStatus: filterStatus != null ? filterStatus() : this.filterStatus,
      userLatitude:
          userLatitude != null ? userLatitude() : this.userLatitude,
      userLongitude:
          userLongitude != null ? userLongitude() : this.userLongitude,
    );
  }
}
