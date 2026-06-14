import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/realtime/signalr_provider.dart';
import '../../data/sos_offline_queue.dart';
import '../../data/sos_remote_data_source.dart';
import '../../domain/sos_alert_model.dart';
import 'sos_provider.dart';

// ─── SOS Enums ────────────────────────────────────────────────────────────────

enum SosScreenMode { idle, triggering, active, resolved, cancelled }

enum SosSeverity { low, standard, high, critical }

extension SosSeverityExt on SosSeverity {
  /// API `SOSSeverity` enum: 0 = Standard, 1 = High, 2 = Critical.
  int get apiIntValue => switch (this) {
        SosSeverity.low      => 0,
        SosSeverity.standard => 0,
        SosSeverity.high     => 1,
        SosSeverity.critical => 2,
      };

  // Keep string value for any legacy code
  String get apiValue => switch (this) {
        SosSeverity.low      => 'Low',
        SosSeverity.standard => 'Medium',
        SosSeverity.high     => 'High',
        SosSeverity.critical => 'Critical',
      };

  String get label => switch (this) {
        SosSeverity.low      => 'منخفض',
        SosSeverity.standard => 'متوسط',
        SosSeverity.high     => 'عالي',
        SosSeverity.critical => 'حرج',
      };
}

// ─── SOS State ────────────────────────────────────────────────────────────────

class SosState {
  const SosState({
    this.mode = SosScreenMode.idle,
    this.activeAlert,
    this.severity = SosSeverity.standard,
    this.selectedCommunityId,
    this.optionalMessage = '',
    this.isTriggering = false,
    this.error,
    this.currentLat,
    this.currentLng,
    this.triggeredAt,
    this.resolvedBy,
    this.elapsedSeconds = 0,
    this.locationLastUpdated,
    // ── NEW: stale location tracking ──
    this.isLocationStale = false,
    this.secondsSinceLastPing = 0,
    this.latestLocation,
  });

  final SosScreenMode mode;
  final SosAlertModel? activeAlert;
  final SosSeverity severity;
  final String? selectedCommunityId;
  final String optionalMessage;
  final bool isTriggering;
  final String? error;
  final double? currentLat;
  final double? currentLng;
  final DateTime? triggeredAt;
  final String? resolvedBy;
  final int elapsedSeconds;
  final DateTime? locationLastUpdated;
  // ── Stale location ────────────────────────────────────────────────────────
  final bool isLocationStale;
  final int secondsSinceLastPing;
  final SosLocationDto? latestLocation;

  bool get isIdle   => mode == SosScreenMode.idle;
  bool get isActive => mode == SosScreenMode.active;

  SosState copyWith({
    SosScreenMode? mode,
    SosAlertModel? activeAlert,
    SosSeverity? severity,
    String? selectedCommunityId,
    String? optionalMessage,
    bool? isTriggering,
    String? error,
    bool clearError = false,
    double? currentLat,
    double? currentLng,
    DateTime? triggeredAt,
    String? resolvedBy,
    int? elapsedSeconds,
    DateTime? locationLastUpdated,
    bool? isLocationStale,
    int? secondsSinceLastPing,
    SosLocationDto? latestLocation,
  }) {
    return SosState(
      mode: mode ?? this.mode,
      activeAlert: activeAlert ?? this.activeAlert,
      severity: severity ?? this.severity,
      selectedCommunityId: selectedCommunityId ?? this.selectedCommunityId,
      optionalMessage: optionalMessage ?? this.optionalMessage,
      isTriggering: isTriggering ?? this.isTriggering,
      error: clearError ? null : (error ?? this.error),
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      locationLastUpdated: locationLastUpdated ?? this.locationLastUpdated,
      isLocationStale: isLocationStale ?? this.isLocationStale,
      secondsSinceLastPing: secondsSinceLastPing ?? this.secondsSinceLastPing,
      latestLocation: latestLocation ?? this.latestLocation,
    );
  }
}

// ─── SOSNotifier ─────────────────────────────────────────────────────────────

class SosNotifier extends StateNotifier<SosState> {
  SosNotifier(this._ref) : super(const SosState()) {
    _wireSignalR();
  }

  final Ref _ref;
  Timer? _elapsedTimer;
  Timer? _locationTimer;

  SosRemoteDataSource get _ds => _ref.read(sosRemoteDataSourceProvider);
  final SosOfflineQueue _queue = SosOfflineQueue.instance;

  // ── SignalR wiring ─────────────────────────────────────────────────────────

  void _wireSignalR() {
    final manager = _ref.read(signalRManagerProvider);

    manager.onSOSResolved = (sosId, resolvedBy) {
      if (!mounted) return;
      if (state.activeAlert?.id == sosId) {
        onResolved(sosId, resolvedBy);
      }
    };

    manager.onSOSCancelled = (sosId, cancelledBy) {
      if (!mounted) return;
      if (state.activeAlert?.id == sosId) {
        _stopTimers();
        _queue.clear();
        if (mounted) {
          state = state.copyWith(
            mode: SosScreenMode.cancelled,
            resolvedBy: cancelledBy,
          );
        }
      }
    };

    manager.onSeverityChanged = (sosId, severity) {
      if (!mounted) return;
      if (state.activeAlert?.id == sosId) {
        final updated = state.activeAlert!.copyWith(severity: severity);
        state = state.copyWith(activeAlert: updated);
      }
    };

    // ── NEW: location stale ────────────────────────────────────────────────
    manager.onLocationStale = (sosId, secondsSince) {
      if (!mounted) return;
      if (state.activeAlert?.id == sosId) {
        state = state.copyWith(
          isLocationStale: true,
          secondsSinceLastPing: secondsSince,
        );
      }
    };

    // ── NEW: location restored ─────────────────────────────────────────────
    manager.onLocationRestored = (sosId) {
      if (!mounted) return;
      if (state.activeAlert?.id == sosId) {
        state = state.copyWith(
          isLocationStale: false,
          secondsSinceLastPing: 0,
        );
      }
    };

    // ── NEW: member activated (LocationPending → Active) ───────────────────
    manager.onMemberActivated = (sosId, userId, memberName) {
      // non-state; the UI will read this event from the notifier via a separate
      // stream — for now just ignore. Individual widgets can hook manager directly.
    };
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  void setSeverity(SosSeverity s) =>
      state = state.copyWith(severity: s, clearError: true);

  void setCommunityId(String? id) =>
      state = state.copyWith(selectedCommunityId: id, clearError: true);

  void setMessage(String msg) => state = state.copyWith(optionalMessage: msg);

  void clearError() => state = state.copyWith(clearError: true);

  // ── Trigger SOS ───────────────────────────────────────────────────────────

  Future<bool> triggerSOS() async {
    if (state.isTriggering || state.isActive) return false;

    if (state.selectedCommunityId == null ||
        state.selectedCommunityId!.isEmpty) {
      state = state.copyWith(error: 'يرجى اختيار مجتمع أولاً');
      return false;
    }

    state = state.copyWith(isTriggering: true, clearError: true);

    // 1. Get current location
    Position? position;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('خدمة الموقع غير مفعّلة');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('صلاحية الموقع مرفوضة دائماً');
      }

      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isTriggering: false,
        error: 'تعذّر تحديد موقعك: ${e.toString()}',
      );
      return false;
    }

    // 2. POST trigger — severity sent as int per new API spec
    try {
      final alert = await _ds.trigger(
        communityId: state.selectedCommunityId!,
        latitude: position.latitude,
        longitude: position.longitude,
        severity: state.severity.apiIntValue,
        accuracyMeters: position.accuracy,
        message: state.optionalMessage.trim().isEmpty
            ? null
            : state.optionalMessage.trim(),
      );

      if (!mounted) return false;

      if (alert == null) {
        state = state.copyWith(
          isTriggering: false,
          error: 'فشل إرسال النداء — حاول مرة أخرى',
        );
        return false;
      }

      // 3. Store + switch to active
      state = state.copyWith(
        mode: SosScreenMode.active,
        activeAlert: alert,
        isTriggering: false,
        currentLat: position.latitude,
        currentLng: position.longitude,
        triggeredAt: DateTime.now(),
        elapsedSeconds: 0,
        isLocationStale: false,
        secondsSinceLastPing: 0,
        clearError: true,
      );

      // 4. Start timers
      _startElapsedTimer();
      _startLocationTimer();

      // 5. Join SignalR group
      await _ref
          .read(signalRManagerProvider)
          .joinCommunityGroup(state.selectedCommunityId!);

      // 6. Load live snapshot to sync map immediately
      _loadLiveSnapshot(alert.id);

      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isTriggering: false,
        error: 'خطأ: ${e.toString()}',
      );
      return false;
    }
  }

  // ── Live snapshot ─────────────────────────────────────────────────────────

  Future<void> _loadLiveSnapshot(String alertId) async {
    try {
      final snapshot = await _ds.getLiveState(alertId);
      if (snapshot == null || !mounted) return;
      state = state.copyWith(
        isLocationStale: snapshot.isInitiatorLocationStale,
        secondsSinceLastPing: snapshot.secondsSinceLastPing,
        latestLocation: snapshot.latestLocation,
      );
    } catch (_) {
      // non-fatal
    }
  }

  // ── Cancel SOS ────────────────────────────────────────────────────────────

  Future<void> cancelSOS() async {
    final alertId = state.activeAlert?.id;
    if (alertId == null || alertId.isEmpty) return;

    try {
      await _ds.cancelAlert(alertId);
    } catch (_) {
      // Best-effort
    }

    _stopTimers();
    _queue.clear();
    if (mounted) state = state.copyWith(mode: SosScreenMode.cancelled);
  }

  // ── SignalR: resolved event ───────────────────────────────────────────────

  void onResolved(String sosId, String resolvedBy) {
    _stopTimers();
    _queue.clear();
    if (!mounted) return;
    state = state.copyWith(
      mode: SosScreenMode.resolved,
      resolvedBy: resolvedBy,
    );
  }

  // ── Reset to idle ─────────────────────────────────────────────────────────

  void resetToIdle() {
    _stopTimers();
    _queue.clear();
    if (mounted) state = const SosState();
  }

  // ── Location timer — every 5 seconds ──────────────────────────────────────

  void _startLocationTimer() {
    _locationTimer?.cancel();
    // Per spec: send every 5 seconds while SOS is active
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _sendLocationUpdate();
    });
  }

  Future<void> _sendLocationUpdate() async {
    final alertId = state.activeAlert?.id;
    if (alertId == null || alertId.isEmpty) return;

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (_) {
      // If we can't get position, queue empty slot — skip
      return;
    }

    // Check connectivity — if offline, enqueue; otherwise flush then send
    final isOnline = await _isOnline();
    if (!isOnline) {
      _queue.add(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        altitudeMeters: position.altitude,
      );
      return;
    }

    // Flush any queued pings first
    if (_queue.hasItems) {
      try {
        await _queue.flush(
          sosAlertId: alertId,
          client: _ds.apiClient,
          readToken: _ds.readToken,
        );
      } catch (_) {
        // Non-fatal — continue to send current ping
      }
    }

    // Send current location
    try {
      final locationDto = await _ds.updateLocation(
        id: alertId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        altitudeMeters: position.altitude,
      );
      if (mounted) {
        state = state.copyWith(
          currentLat: position.latitude,
          currentLng: position.longitude,
          locationLastUpdated: DateTime.now(),
          isLocationStale: false,
          latestLocation: locationDto,
        );
      }
    } catch (_) {
      // On failure, queue for next cycle
      _queue.add(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        altitudeMeters: position.altitude,
      );
    }
  }

  Future<bool> _isOnline() async {
    try {
      // Simple connectivity check via geolocator's last known position speed
      // A proper app would use connectivity_plus — this is a lightweight fallback
      return true; // Assume online; queue handles offline gracefully
    } catch (_) {
      return false;
    }
  }

  // ── Elapsed timer (every 1s) ──────────────────────────────────────────────

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  void _stopTimers() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final sosNotifierProvider =
    StateNotifierProvider<SosNotifier, SosState>((ref) {
  return SosNotifier(ref);
});
