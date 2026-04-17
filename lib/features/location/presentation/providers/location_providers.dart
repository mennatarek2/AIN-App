import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/location_local_data_source.dart';
import '../../data/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationLocalDataSourceProvider = Provider<LocationLocalDataSource>((
  ref,
) {
  return LocationLocalDataSource();
});

class ReportLocationState {
  const ReportLocationState({
    this.selectedLatLng,
    this.selectedAddress,
    this.accessStatus = LocationAccessStatus.denied,
    this.isLoading = false,
    this.isResolvingAddress = false,
    this.errorMessage,
  });

  final LatLng? selectedLatLng;
  final String? selectedAddress;
  final LocationAccessStatus accessStatus;
  final bool isLoading;
  final bool isResolvingAddress;
  final String? errorMessage;

  bool get canShowMap =>
      accessStatus == LocationAccessStatus.granted || selectedLatLng != null;

  ReportLocationState copyWith({
    LatLng? selectedLatLng,
    String? selectedAddress,
    LocationAccessStatus? accessStatus,
    bool? isLoading,
    bool? isResolvingAddress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReportLocationState(
      selectedLatLng: selectedLatLng ?? this.selectedLatLng,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      accessStatus: accessStatus ?? this.accessStatus,
      isLoading: isLoading ?? this.isLoading,
      isResolvingAddress: isResolvingAddress ?? this.isResolvingAddress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ReportLocationNotifier extends StateNotifier<ReportLocationState> {
  ReportLocationNotifier(this._service, this._localDataSource)
    : super(const ReportLocationState());

  final LocationService _service;
  final LocationLocalDataSource _localDataSource;

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final cachedLocation = await _localDataSource.getLastKnownLocation();
    if (cachedLocation != null) {
      state = state.copyWith(
        selectedLatLng: LatLng(
          cachedLocation.latitude,
          cachedLocation.longitude,
        ),
        selectedAddress: cachedLocation.address,
      );
    }

    final accessResult = await _service.ensureLocationAccess();
    if (!accessResult.isGranted) {
      state = state.copyWith(
        accessStatus: accessResult.status,
        isLoading: false,
        errorMessage: accessResult.message,
      );
      return;
    }

    final position = await _service.getCurrentPosition();
    if (position == null) {
      if (cachedLocation != null) {
        state = state.copyWith(
          accessStatus: LocationAccessStatus.granted,
          selectedLatLng: LatLng(
            cachedLocation.latitude,
            cachedLocation.longitude,
          ),
          selectedAddress: cachedLocation.address,
          isLoading: false,
          errorMessage: 'GPS unavailable. Using cached location.',
        );
        return;
      }

      state = state.copyWith(
        accessStatus: LocationAccessStatus.granted,
        isLoading: false,
        errorMessage: 'Unable to fetch current location.',
      );
      return;
    }

    final initialTarget = LatLng(position.latitude, position.longitude);
    state = state.copyWith(
      accessStatus: LocationAccessStatus.granted,
      selectedLatLng: initialTarget,
      isLoading: false,
      clearError: true,
    );

    await _resolveAddress(initialTarget);
  }

  Future<void> selectLocation(LatLng latLng) async {
    state = state.copyWith(selectedLatLng: latLng, clearError: true);
    await _resolveAddress(latLng);
  }

  Future<void> refreshCurrentLocation() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final position = await _service.getCurrentPosition();

    if (position == null) {
      final cachedLocation = await _localDataSource.getLastKnownLocation();
      if (cachedLocation != null) {
        state = state.copyWith(
          selectedLatLng: LatLng(
            cachedLocation.latitude,
            cachedLocation.longitude,
          ),
          selectedAddress: cachedLocation.address,
          accessStatus: LocationAccessStatus.granted,
          isLoading: false,
          errorMessage: 'GPS unavailable. Using cached location.',
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to refresh current location.',
      );
      return;
    }

    final target = LatLng(position.latitude, position.longitude);
    state = state.copyWith(
      selectedLatLng: target,
      isLoading: false,
      accessStatus: LocationAccessStatus.granted,
    );
    await _resolveAddress(target);
  }

  Future<void> openPermissionSettings() async {
    await _service.openPermissionSettings();
  }

  Future<void> openDeviceLocationSettings() async {
    await _service.openDeviceLocationSettings();
  }

  Future<void> _resolveAddress(LatLng latLng) async {
    state = state.copyWith(isResolvingAddress: true);
    final address = await _service.getReadableAddress(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );

    if (!mounted) return;
    state = state.copyWith(selectedAddress: address, isResolvingAddress: false);
    await _localDataSource.saveLastKnownLocation(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      address: address,
    );
  }
}

final reportLocationProvider =
    StateNotifierProvider.autoDispose<
      ReportLocationNotifier,
      ReportLocationState
    >((ref) {
      return ReportLocationNotifier(
        ref.watch(locationServiceProvider),
        ref.watch(locationLocalDataSourceProvider),
      );
    });

class LiveLocationState {
  const LiveLocationState({
    this.currentPosition,
    this.accessStatus = LocationAccessStatus.denied,
    this.isTracking = false,
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdated,
  });

  final Position? currentPosition;
  final LocationAccessStatus accessStatus;
  final bool isTracking;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdated;

  bool get canShowMap => accessStatus == LocationAccessStatus.granted;

  LiveLocationState copyWith({
    Position? currentPosition,
    LocationAccessStatus? accessStatus,
    bool? isTracking,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdated,
    bool clearError = false,
  }) {
    return LiveLocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      accessStatus: accessStatus ?? this.accessStatus,
      isTracking: isTracking ?? this.isTracking,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class LiveLocationNotifier extends StateNotifier<LiveLocationState> {
  LiveLocationNotifier(this._service, this._localDataSource)
    : super(const LiveLocationState());

  final LocationService _service;
  final LocationLocalDataSource _localDataSource;
  StreamSubscription<Position>? _positionSubscription;

  Future<void> startTracking() async {
    if (state.isTracking) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final access = await _service.ensureLocationAccess();
    if (!access.isGranted) {
      final cachedPosition = await _getCachedPosition();
      state = state.copyWith(
        currentPosition: cachedPosition,
        accessStatus: access.status,
        isLoading: false,
        isTracking: false,
        errorMessage: cachedPosition == null
            ? access.message
            : 'GPS unavailable. Using cached location.',
      );
      return;
    }

    final currentPosition = await _service.getCurrentPosition();
    if (currentPosition != null) {
      await _persistPosition(currentPosition);
      state = state.copyWith(
        currentPosition: currentPosition,
        accessStatus: LocationAccessStatus.granted,
        lastUpdated: DateTime.now(),
      );
    } else {
      final cachedPosition = await _getCachedPosition();
      if (cachedPosition != null) {
        state = state.copyWith(
          currentPosition: cachedPosition,
          accessStatus: LocationAccessStatus.granted,
          lastUpdated: DateTime.now(),
        );
      }
    }

    await _positionSubscription?.cancel();
    _positionSubscription = _service
        .getPositionStream(
          interval: const Duration(seconds: 7),
          distanceFilterMeters: 15,
        )
        .listen(
          (position) {
            if (!mounted) return;
            unawaited(_persistPosition(position));
            state = state.copyWith(
              currentPosition: position,
              accessStatus: LocationAccessStatus.granted,
              isTracking: true,
              isLoading: false,
              lastUpdated: DateTime.now(),
              clearError: true,
            );
          },
          onError: (error) {
            if (!mounted) return;
            state = state.copyWith(
              isTracking: false,
              isLoading: false,
              errorMessage: 'Live location stream failed.',
            );
          },
        );

    state = state.copyWith(
      isTracking: true,
      isLoading: false,
      accessStatus: LocationAccessStatus.granted,
    );
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    if (!mounted) return;
    state = state.copyWith(isTracking: false);
  }

  Future<void> openPermissionSettings() async {
    await _service.openPermissionSettings();
  }

  Future<void> openDeviceLocationSettings() async {
    await _service.openDeviceLocationSettings();
  }

  Future<Position?> _getCachedPosition() async {
    final cachedLocation = await _localDataSource.getLastKnownLocation();
    if (cachedLocation == null) return null;

    return Position(
      longitude: cachedLocation.longitude,
      latitude: cachedLocation.latitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  Future<void> _persistPosition(Position position) {
    return _localDataSource.saveLastKnownLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

final liveLocationProvider =
    StateNotifierProvider.autoDispose<LiveLocationNotifier, LiveLocationState>((
      ref,
    ) {
      final notifier = LiveLocationNotifier(
        ref.watch(locationServiceProvider),
        ref.watch(locationLocalDataSourceProvider),
      );
      ref.onDispose(notifier.stopTracking);
      return notifier;
    });

class LiveUserLocation {
  const LiveUserLocation({
    required this.userId,
    required this.name,
    required this.communityId,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
    this.isCurrentUser = false,
  });

  final String userId;
  final String name;
  final String communityId;
  final double latitude;
  final double longitude;
  final DateTime lastUpdated;
  final bool isCurrentUser;

  LatLng get latLng => LatLng(latitude, longitude);

  Map<String, dynamic> toBackendDocument() {
    return {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  LiveUserLocation copyWith({
    String? userId,
    String? name,
    String? communityId,
    double? latitude,
    double? longitude,
    DateTime? lastUpdated,
    bool? isCurrentUser,
  }) {
    return LiveUserLocation(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      communityId: communityId ?? this.communityId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}

class CommunityLiveLocationState {
  const CommunityLiveLocationState({
    required this.users,
    this.accessStatus = LocationAccessStatus.denied,
    this.isLoading = false,
    this.isTracking = false,
    this.errorMessage,
  });

  final List<LiveUserLocation> users;
  final LocationAccessStatus accessStatus;
  final bool isLoading;
  final bool isTracking;
  final String? errorMessage;

  CommunityLiveLocationState copyWith({
    List<LiveUserLocation>? users,
    LocationAccessStatus? accessStatus,
    bool? isLoading,
    bool? isTracking,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CommunityLiveLocationState(
      users: users ?? this.users,
      accessStatus: accessStatus ?? this.accessStatus,
      isLoading: isLoading ?? this.isLoading,
      isTracking: isTracking ?? this.isTracking,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CommunityLiveLocationNotifier
    extends StateNotifier<CommunityLiveLocationState> {
  CommunityLiveLocationNotifier(this._service)
    : super(const CommunityLiveLocationState(users: []));

  final LocationService _service;
  final Random _random = Random();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _mockUsersTimer;

  static const _currentUserId = 'current-user';

  final List<LiveUserLocation> _mockUsers = [
    LiveUserLocation(
      userId: 'u-laila',
      name: 'Laila',
      communityId: 'comm-1',
      latitude: 30.0522,
      longitude: 31.2448,
      lastUpdated: DateTime.now(),
    ),
    LiveUserLocation(
      userId: 'u-amr',
      name: 'Amr',
      communityId: 'comm-1',
      latitude: 30.0469,
      longitude: 31.2327,
      lastUpdated: DateTime.now(),
    ),
    LiveUserLocation(
      userId: 'u-mahmoud',
      name: 'Mahmoud',
      communityId: 'comm-2',
      latitude: 30.0308,
      longitude: 31.2201,
      lastUpdated: DateTime.now(),
    ),
    LiveUserLocation(
      userId: 'u-abdulrahman',
      name: 'Abdulrahman',
      communityId: 'comm-2',
      latitude: 30.0374,
      longitude: 31.2369,
      lastUpdated: DateTime.now(),
    ),
  ];

  Future<void> startTracking({String currentUserCommunityId = 'comm-1'}) async {
    if (state.isTracking) {
      final index = state.users.indexWhere(
        (user) => user.userId == _currentUserId,
      );
      if (index != -1) {
        final updatedCurrent = state.users[index].copyWith(
          communityId: currentUserCommunityId,
          lastUpdated: DateTime.now(),
        );
        state = state.copyWith(users: _upsertUser(state.users, updatedCurrent));
      }
      return;
    }

    state = state.copyWith(
      isLoading: true,
      users: [..._mockUsers],
      clearError: true,
    );

    final access = await _service.ensureLocationAccess();
    if (!access.isGranted) {
      state = state.copyWith(
        accessStatus: access.status,
        isLoading: false,
        isTracking: false,
        errorMessage: access.message,
      );
      _startMockUsersSimulation();
      return;
    }

    final currentPosition = await _service.getCurrentPosition();
    final currentUser = LiveUserLocation(
      userId: _currentUserId,
      name: 'You',
      communityId: currentUserCommunityId,
      latitude: currentPosition?.latitude ?? 30.0444,
      longitude: currentPosition?.longitude ?? 31.2357,
      lastUpdated: DateTime.now(),
      isCurrentUser: true,
    );

    state = state.copyWith(
      users: _upsertUser(state.users, currentUser),
      accessStatus: LocationAccessStatus.granted,
      isLoading: false,
      isTracking: true,
    );

    await _positionSubscription?.cancel();
    _positionSubscription = _service
        .getPositionStream(
          interval: const Duration(seconds: 7),
          distanceFilterMeters: 15,
        )
        .listen(
          (position) {
            if (!mounted) return;
            final updatedCurrentUser = LiveUserLocation(
              userId: _currentUserId,
              name: 'You',
              communityId: currentUserCommunityId,
              latitude: position.latitude,
              longitude: position.longitude,
              lastUpdated: DateTime.now(),
              isCurrentUser: true,
            );

            state = state.copyWith(
              users: _upsertUser(state.users, updatedCurrentUser),
              accessStatus: LocationAccessStatus.granted,
              isTracking: true,
              isLoading: false,
              clearError: true,
            );
          },
          onError: (_) {
            if (!mounted) return;
            state = state.copyWith(
              isTracking: false,
              errorMessage: 'Unable to update user location in real-time.',
            );
          },
        );

    _startMockUsersSimulation();
  }

  List<LiveUserLocation> usersForCommunity(String communityId) {
    return state.users
        .where((user) => user.communityId == communityId)
        .toList();
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _mockUsersTimer?.cancel();
    _mockUsersTimer = null;

    if (!mounted) return;
    state = state.copyWith(isTracking: false);
  }

  Future<void> openPermissionSettings() async {
    await _service.openPermissionSettings();
  }

  Future<void> openDeviceLocationSettings() async {
    await _service.openDeviceLocationSettings();
  }

  void _startMockUsersSimulation() {
    _mockUsersTimer?.cancel();
    _mockUsersTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;

      final updatedUsers = state.users
          .map(
            (user) => user.isCurrentUser
                ? user
                : user.copyWith(
                    latitude:
                        user.latitude + (_random.nextDouble() - 0.5) * 0.0004,
                    longitude:
                        user.longitude + (_random.nextDouble() - 0.5) * 0.0004,
                    lastUpdated: DateTime.now(),
                  ),
          )
          .toList();

      state = state.copyWith(users: updatedUsers);
    });
  }

  List<LiveUserLocation> _upsertUser(
    List<LiveUserLocation> users,
    LiveUserLocation incoming,
  ) {
    final index = users.indexWhere((user) => user.userId == incoming.userId);
    if (index == -1) {
      return [...users, incoming];
    }

    final nextUsers = [...users];
    nextUsers[index] = incoming;
    return nextUsers;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mockUsersTimer?.cancel();
    super.dispose();
  }
}

final communityLiveLocationProvider =
    StateNotifierProvider.autoDispose<
      CommunityLiveLocationNotifier,
      CommunityLiveLocationState
    >((ref) {
      final notifier = CommunityLiveLocationNotifier(
        ref.watch(locationServiceProvider),
      );
      ref.onDispose(notifier.stopTracking);
      return notifier;
    });

final communityUsersProvider = Provider.family<List<LiveUserLocation>, String>((
  ref,
  communityId,
) {
  final notifier = ref.read(communityLiveLocationProvider.notifier);
  ref.watch(communityLiveLocationProvider);
  return notifier.usersForCommunity(communityId);
});
