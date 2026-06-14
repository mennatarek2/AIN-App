import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../network/api_config.dart';
import 'signalr_state.dart';

// ─── Callback typedefs ────────────────────────────────────────────────────────

typedef SosTriggeredCallback = void Function(Map<String, dynamic> alert);
typedef SosResolvedCallback = void Function(String sosId, String resolvedBy);
typedef SosCancelledCallback = void Function(String sosId, String cancelledBy);
typedef SosLocationCallback = void Function(String sosId, dynamic location);
typedef SosSeverityCallback = void Function(String sosId, String severity);
typedef SosFalseAlarmCallback = void Function(String sosId, String markedBy);
typedef ConnectionStatusCallback = void Function(SignalRStatus status);
// ── NEW callbacks ─────────────────────────────────────────────────────────────
typedef LocationStaleCallback = void Function(String sosId, int secondsSince);
typedef LocationRestoredCallback = void Function(String sosId);
typedef MemberActivatedCallback = void Function(String sosId, String userId, String memberName);

// ─── Manager ─────────────────────────────────────────────────────────────────

class SignalRManager {
  SignalRManager();

  HubConnection? _connection;
  SignalRStatus _status = SignalRStatus.disconnected;
  bool _disposed = false;

  // ── Callbacks (set by consumers) ──────────────────────────────────────────
  SosTriggeredCallback? onSOSTriggered;
  SosResolvedCallback? onSOSResolved;
  SosCancelledCallback? onSOSCancelled;
  SosLocationCallback? onLocationUpdate;
  SosSeverityCallback? onSeverityChanged;
  SosFalseAlarmCallback? onFalseAlarm;
  ConnectionStatusCallback? onConnectionStatusChanged;
  // ── NEW ───────────────────────────────────────────────────────────────────
  LocationStaleCallback? onLocationStale;
  LocationRestoredCallback? onLocationRestored;
  MemberActivatedCallback? onMemberActivated;

  SignalRStatus get status => _status;
  bool get isConnected => _status == SignalRStatus.connected;

  // ── Initialize ────────────────────────────────────────────────────────────

  Future<void> initialize(String token) async {
    if (_disposed) return;
    if (_connection != null) await _connection!.stop();

    final hubUrl = '${ApiConfig.baseUrl}/hub/sos';

    _connection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
            transport: HttpTransportType.WebSockets,
            logMessageContent: false,
          ),
        )
        .withAutomaticReconnect(
          retryDelays: [0, 2000, 5000, 10000, 30000],
        )
        .configureLogging(Logger('SignalR'))
        .build();

    _registerEventHandlers();

    _connection!.onreconnected(({connectionId}) {
      _setStatus(SignalRStatus.connected);
      debugPrint('[SignalR] Reconnected. connectionId=$connectionId');
    });

    _connection!.onreconnecting(({error}) {
      _setStatus(SignalRStatus.reconnecting);
      debugPrint('[SignalR] Reconnecting… error=$error');
    });

    _connection!.onclose(({error}) {
      _setStatus(SignalRStatus.disconnected);
      debugPrint('[SignalR] Connection closed. error=$error');
    });

    await _startWithRetry();
  }

  // ── Event handlers ────────────────────────────────────────────────────────

  void _registerEventHandlers() {
    final conn = _connection!;

    conn.on('ReceiveSOSTriggered', (args) {
      try {
        final raw = args?.firstOrNull;
        if (raw == null) return;
        final map = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from(raw as Map);
        onSOSTriggered?.call(map);
      } catch (e) {
        debugPrint('[SignalR] ReceiveSOSTriggered parse error: $e');
      }
    });

    conn.on('ReceiveSOSResolved', (args) {
      try {
        final sosId = args?[0]?.toString() ?? '';
        final resolvedBy = args?[1]?.toString() ?? '';
        onSOSResolved?.call(sosId, resolvedBy);
      } catch (e) {
        debugPrint('[SignalR] ReceiveSOSResolved parse error: $e');
      }
    });

    conn.on('ReceiveSOSCancelled', (args) {
      try {
        final sosId = args?[0]?.toString() ?? '';
        final cancelledBy = args?[1]?.toString() ?? '';
        onSOSCancelled?.call(sosId, cancelledBy);
      } catch (e) {
        debugPrint('[SignalR] ReceiveSOSCancelled parse error: $e');
      }
    });

    conn.on('ReceiveLocationUpdate', (args) {
      try {
        final sosId = args?[0]?.toString() ?? '';
        onLocationUpdate?.call(sosId, args?[1]);
      } catch (e) {
        debugPrint('[SignalR] ReceiveLocationUpdate parse error: $e');
      }
    });

    conn.on('ReceiveSeverityChanged', (args) {
      try {
        final sosId = args?[0]?.toString() ?? '';
        final severity = args?[1]?.toString() ?? '';
        onSeverityChanged?.call(sosId, severity);
      } catch (e) {
        debugPrint('[SignalR] ReceiveSeverityChanged parse error: $e');
      }
    });

    conn.on('ReceiveSOSMarkedAsFalseAlarm', (args) {
      try {
        final sosId = args?[0]?.toString() ?? '';
        final markedBy = args?[1]?.toString() ?? '';
        onFalseAlarm?.call(sosId, markedBy);
      } catch (e) {
        debugPrint('[SignalR] ReceiveSOSMarkedAsFalseAlarm parse error: $e');
      }
    });

    // ── NEW events ────────────────────────────────────────────────────────────

    // Location went stale (>60s no ping)
    conn.on('ReceiveLocationStale', (args) {
      try {
        final sosId = args?[0]?.toString() ?? '';
        final seconds = args?[1] is int
            ? args![1] as int
            : int.tryParse(args?[1]?.toString() ?? '') ?? 0;
        onLocationStale?.call(sosId, seconds);
      } catch (e) {
        debugPrint('[SignalR] ReceiveLocationStale parse error: $e');
      }
    });

    // Location resumed after stale period
    conn.on('ReceiveLocationRestored', (args) {
      try {
        final sosId = args?[0]?.toString() ?? '';
        onLocationRestored?.call(sosId);
      } catch (e) {
        debugPrint('[SignalR] ReceiveLocationRestored parse error: $e');
      }
    });

    // LocationPending member shared location during active SOS
    conn.on('ReceiveSOSMemberActivated', (args) {
      try {
        final sosId = args?[0]?.toString() ?? '';
        final userId = args?[1]?.toString() ?? '';
        final memberName = args?[2]?.toString() ?? '';
        onMemberActivated?.call(sosId, userId, memberName);
      } catch (e) {
        debugPrint('[SignalR] ReceiveSOSMemberActivated parse error: $e');
      }
    });
  }

  // ── Community group operations ────────────────────────────────────────────

  Future<void> joinCommunityGroup(String communityId) async {
    if (!isConnected || communityId.isEmpty) return;
    try {
      await _connection!.invoke('JoinCommunityGroup', args: [communityId]);
      debugPrint('[SignalR] Joined community group: $communityId');
    } catch (e) {
      debugPrint('[SignalR] Failed to join group $communityId: $e');
    }
  }

  Future<void> leaveCommunityGroup(String communityId) async {
    if (!isConnected || communityId.isEmpty) return;
    try {
      await _connection!.invoke('LeaveCommunityGroup', args: [communityId]);
      debugPrint('[SignalR] Left community group: $communityId');
    } catch (e) {
      debugPrint('[SignalR] Failed to leave group $communityId: $e');
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _startWithRetry() async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (_disposed) return;
      try {
        _setStatus(SignalRStatus.connecting);
        await _connection!.start();
        _setStatus(SignalRStatus.connected);
        debugPrint('[SignalR] Connected (attempt $attempt).');
        return;
      } catch (e) {
        debugPrint('[SignalR] Start attempt $attempt failed: $e');
        if (attempt < maxAttempts) {
          await Future<void>.delayed(
            Duration(seconds: attempt * 2),
          );
        }
      }
    }
    _setStatus(SignalRStatus.error);
  }

  void _setStatus(SignalRStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    onConnectionStatusChanged?.call(newStatus);
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    _disposed = true;
    try {
      await _connection?.stop();
    } catch (_) {}
    _connection = null;
    _setStatus(SignalRStatus.disconnected);
  }
}
