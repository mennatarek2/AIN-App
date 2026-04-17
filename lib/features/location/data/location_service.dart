import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum LocationAccessStatus {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

class LocationAccessResult {
  const LocationAccessResult({required this.status, this.message});

  final LocationAccessStatus status;
  final String? message;

  bool get isGranted => status == LocationAccessStatus.granted;
}

class LocationService {
  Future<LocationAccessResult> ensureLocationAccess({
    bool requestPermission = true,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationAccessResult(
        status: LocationAccessStatus.serviceDisabled,
        message: 'Location service is disabled.',
      );
    }

    PermissionStatus permissionStatus =
        await Permission.locationWhenInUse.status;

    if (!permissionStatus.isGranted && requestPermission) {
      permissionStatus = await Permission.locationWhenInUse.request();
    }

    if (permissionStatus.isGranted || permissionStatus.isLimited) {
      return const LocationAccessResult(status: LocationAccessStatus.granted);
    }

    if (permissionStatus.isPermanentlyDenied || permissionStatus.isRestricted) {
      return const LocationAccessResult(
        status: LocationAccessStatus.permanentlyDenied,
        message: 'Location permission is permanently denied.',
      );
    }

    return const LocationAccessResult(
      status: LocationAccessStatus.denied,
      message: 'Location permission is denied.',
    );
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Stream<Position> getPositionStream({
    Duration interval = const Duration(seconds: 7),
    int distanceFilterMeters = 15,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: _buildLocationSettings(
        interval: interval,
        distanceFilterMeters: distanceFilterMeters,
        accuracy: accuracy,
      ),
    );
  }

  Future<String?> getReadableAddress({
    required double latitude,
    required double longitude,
    String? localeIdentifier,
  }) async {
    try {
      if (localeIdentifier != null && localeIdentifier.trim().isNotEmpty) {
        await setLocaleIdentifier(localeIdentifier);
      }

      final places = await placemarkFromCoordinates(latitude, longitude);
      if (places.isEmpty) return null;
      final place = places.first;

      final street = _firstNonEmpty([
        place.street,
        place.name,
        place.subLocality,
      ]);
      final city = _firstNonEmpty([
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
      ]);

      if (street != null && city != null) {
        return '$street، $city';
      }
      if (street != null) return street;
      if (city != null) return city;

      final parts = [
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
      ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();

      if (parts.isEmpty) return null;
      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Future<void> openDeviceLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openPermissionSettings() async {
    await openAppSettings();
  }

  LocationSettings _buildLocationSettings({
    required Duration interval,
    required int distanceFilterMeters,
    required LocationAccuracy accuracy,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
        intervalDuration: interval,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: true,
      );
    }

    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilterMeters,
    );
  }
}
