import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../location/data/location_local_data_source.dart';
import '../../../location/data/location_service.dart';
import '../../../location/presentation/providers/location_providers.dart';

class HomeLocationState {
  const HomeLocationState({
    this.address,
    this.isLoading = false,
    this.hasRequested = false,
  });

  final String? address;
  final bool isLoading;
  final bool hasRequested;

  HomeLocationState copyWith({
    String? address,
    bool? isLoading,
    bool? hasRequested,
  }) {
    return HomeLocationState(
      address: address ?? this.address,
      isLoading: isLoading ?? this.isLoading,
      hasRequested: hasRequested ?? this.hasRequested,
    );
  }
}

class HomeLocationNotifier extends StateNotifier<HomeLocationState> {
  HomeLocationNotifier(this._service, this._localDataSource)
    : super(const HomeLocationState());

  final LocationService _service;
  final LocationLocalDataSource _localDataSource;

  Future<void> requestLocationIfNeeded() async {
    if (state.hasRequested) return;
    state = state.copyWith(hasRequested: true, isLoading: true);

    final cached = await _localDataSource.getLastKnownLocation();
    if (cached?.address != null && cached!.address!.isNotEmpty) {
      state = state.copyWith(address: cached.address, isLoading: false);
    }

    final access = await _service.ensureLocationAccess();
    if (!access.isGranted) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final position = await _service.getCurrentPosition();
    if (position == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final latLng = LatLng(position.latitude, position.longitude);
    final address = await _service.getReadableAddress(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );

    if (!mounted) return;
    state = state.copyWith(address: address, isLoading: false);

    await _localDataSource.saveLastKnownLocation(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      address: address,
    );
  }
}

final homeLocationProvider =
    StateNotifierProvider<HomeLocationNotifier, HomeLocationState>((ref) {
      return HomeLocationNotifier(
        ref.watch(locationServiceProvider),
        ref.watch(locationLocalDataSourceProvider),
      );
    });
