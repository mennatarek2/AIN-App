import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/realtime/signalr_provider.dart';
import '../../core/realtime/signalr_state.dart';
import '../../features/community/presentation/providers/communities_provider.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';

/// Bootstraps SignalR for a logged-in user:
///   1. Initializes the hub connection
///   2. Wires SignalR events → NotificationsNotifier
///   3. Joins all community groups the user belongs to
///
/// Call this once after login / on app resume.
class SignalRBridge {
  SignalRBridge(this._ref);

  final Ref _ref;
  bool _started = false;

  Future<void> start({required String token}) async {
    if (_started) return;
    _started = true;

    final manager = _ref.read(signalRManagerProvider);
    final statusNotifier = _ref.read(signalRStatusProvider.notifier);

    // ── Wire connection status → reactive provider ─────────────────────────
    manager.onConnectionStatusChanged = (status) {
      statusNotifier.setStatus(status);
    };

    // ── Wire SOS events → NotificationsNotifier + CommunitiesNotifier ───────
    manager.onSOSTriggered = (alert) {
      final sosId = alert['id']?.toString() ?? '';
      final severity = alert['severity']?.toString() ?? 'Standard';
      final message = alert['message']?.toString();
      final communityName = alert['communityName']?.toString();

      _ref.read(notificationsProvider.notifier).addSOSNotification(
        sosId: sosId,
        severity: severity,
        message: message,
        communityName: communityName,
      );
      _ref.read(communitiesProvider.notifier).handleSosTriggered(alert);
    };

    manager.onSOSResolved = (sosId, resolvedBy) {
      _ref.read(notificationsProvider.notifier).addSOSResolvedNotification(
        sosId: sosId,
        resolvedBy: resolvedBy,
      );
      _ref.read(communitiesProvider.notifier).handleSosEnded(sosId);
    };

    manager.onSOSCancelled = (sosId, cancelledBy) {
      _ref.read(communitiesProvider.notifier).handleSosEnded(sosId);
    };

    // ── Initialize connection ──────────────────────────────────────────────
    await manager.initialize(token);

    // ── Join all community groups ──────────────────────────────────────────
    try {
      final communities = _ref.read(communitiesProvider).communities;
      for (final community in communities) {
        await manager.joinCommunityGroup(community.id);
      }
    } catch (_) {
      // Non-fatal; groups can be joined when communities load.
    }
  }

  Future<void> stop() async {
    _started = false;
    await _ref.read(signalRManagerProvider).dispose();
    _ref.read(signalRStatusProvider.notifier).setStatus(
      SignalRStatus.disconnected,
    );
  }
}

final signalRBridgeProvider = Provider<SignalRBridge>((ref) {
  return SignalRBridge(ref);
});
