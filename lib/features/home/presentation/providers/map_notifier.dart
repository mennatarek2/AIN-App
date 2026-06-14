import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../location/data/location_service.dart';
import '../../../location/presentation/providers/location_providers.dart';
import '../../data/map_remote_data_source.dart';
import '../../domain/report_map_pin.dart';
import 'map_state.dart';

// ─── Provider ───────────────────────────────────────────────────────────────

final mapRemoteDataSourceProvider = Provider<MapRemoteDataSource>((ref) {
  final userLocal = ref.watch(userLocalDataSourceProvider);
  return MapRemoteDataSource(
    ref.watch(apiClientProvider),
    readToken: userLocal.getCachedToken,
  );
});

/// Main map state provider — NOT auto-disposed so the map persists zoom level
/// when the user switches tabs and comes back.
final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  final dataSource = ref.watch(mapRemoteDataSourceProvider);
  final locationService = ref.watch(locationServiceProvider);
  return MapNotifier(dataSource, locationService)..loadPins();
});

// ─── Notifier ────────────────────────────────────────────────────────────────

class MapNotifier extends StateNotifier<MapState> {
  MapNotifier(this._dataSource, this._locationService)
      : super(const MapState());

  final MapRemoteDataSource _dataSource;
  final LocationService _locationService;

  // ── Load / Refresh ────────────────────────────────────────────────────────

  Future<void> loadPins() async {
    if (state.isLoading) return;
    if (mounted) {
      state = state.copyWith(isLoading: true, error: () => null);
    }
    try {
      final pins = await _dataSource.fetchMapPins(
        categoryId: state.filterCategoryId,
        status: state.filterStatus,
      );
      if (mounted) {
        state = state.copyWith(
          pins: pins,
          isLoading: false,
          error: () => null,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: () => 'فشل تحميل البيانات: ${e.toString()}',
        );
      }
    }
  }

  Future<void> refresh() => loadPins();

  // ── Pin Selection ─────────────────────────────────────────────────────────

  void selectPin(ReportMapPin? pin) {
    if (mounted) {
      state = state.copyWith(selectedPin: () => pin);
    }
  }

  void deselectPin() => selectPin(null);

  // ── Filters ───────────────────────────────────────────────────────────────

  void applyFilter({String? categoryId, String? status}) {
    if (mounted) {
      state = state.copyWith(
        filterCategoryId: () => categoryId,
        filterStatus: () => status,
        selectedPin: () => null,
      );
    }
    loadPins();
  }

  void clearFilters() => applyFilter();

  // ── My Location ───────────────────────────────────────────────────────────

  /// Requests location permission, gets current position, and stores it
  /// in state so the UI can animate the map and show a blue dot.
  /// Returns `true` on success, `false` on failure.
  Future<bool> locateMe() async {
    final access =
        await _locationService.ensureLocationAccess(requestPermission: true);
    if (!access.isGranted) return false;

    final position = await _locationService.getCurrentPosition();
    if (position == null) return false;

    if (mounted) {
      state = state.copyWith(
        userLatitude: () => position.latitude,
        userLongitude: () => position.longitude,
      );
    }
    return true;
  }
}
