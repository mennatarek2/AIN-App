// lib/features/sos/data/sos_offline_queue.dart
//
// Queues SOS location pings while the device is offline.
// When connectivity returns the SOS notifier flushes the queue
// via POST /api/SOSAlerts/{id}/locations/batch (max 50 items).

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

// ─── DTO ──────────────────────────────────────────────────────────────────────

class SosLocationItem {
  const SosLocationItem({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.altitudeMeters,
    required this.recordedAtUtc,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final double? altitudeMeters;
  final DateTime recordedAtUtc;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
        if (altitudeMeters != null) 'altitudeMeters': altitudeMeters,
        'recordedAtUtc': recordedAtUtc.toUtc().toIso8601String(),
      };
}

// ─── Queue ────────────────────────────────────────────────────────────────────

class SosOfflineQueue {
  SosOfflineQueue._();
  static final instance = SosOfflineQueue._();

  final List<SosLocationItem> _queue = [];

  /// Server maximum is 50 items per batch.
  static const int maxQueueSize = 50;

  bool get hasItems => _queue.isNotEmpty;
  int get length => _queue.length;

  /// Adds a location ping. Drops the oldest item when the max is reached.
  void add({
    required double latitude,
    required double longitude,
    double? accuracyMeters,
    double? altitudeMeters,
  }) {
    if (_queue.length >= maxQueueSize) {
      _queue.removeAt(0); // drop oldest, keep most recent 50
    }
    _queue.add(SosLocationItem(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      altitudeMeters: altitudeMeters,
      recordedAtUtc: DateTime.now().toUtc(),
    ));
  }

  /// Uploads all queued pings to the server in a single batch request.
  /// Re-queues on failure so pings are not lost.
  Future<void> flush({
    required String sosAlertId,
    required ApiClient client,
    required Future<String?> Function() readToken,
  }) async {
    if (_queue.isEmpty) return;

    final batch = List<SosLocationItem>.from(_queue);
    _queue.clear();

    try {
      final token = await readToken();
      await client.postJson(
        ApiEndpoints.sosBatchLocation(sosAlertId),
        token: token,
        body: {
          'locations': batch.map((l) => l.toJson()).toList(),
        },
      );
    } catch (_) {
      // Re-queue on failure — prepend so oldest pings stay first
      _queue.insertAll(0, batch);
      rethrow;
    }
  }

  void clear() => _queue.clear();
}
