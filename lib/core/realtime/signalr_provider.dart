import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'signalr_manager.dart';
import 'signalr_state.dart';

// ─── SignalRManager singleton provider ───────────────────────────────────────

final signalRManagerProvider = Provider<SignalRManager>((ref) {
  final manager = SignalRManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

// ─── Connection status provider ──────────────────────────────────────────────

/// Reactive provider that UI screens can watch to show the disconnection banner.
/// Updated by calling [signalRStatusNotifierProvider.notifier].setStatus().
final signalRStatusProvider =
    StateNotifierProvider<_SignalRStatusNotifier, SignalRStatus>((ref) {
  return _SignalRStatusNotifier();
});

class _SignalRStatusNotifier extends StateNotifier<SignalRStatus> {
  _SignalRStatusNotifier() : super(SignalRStatus.disconnected);

  void setStatus(SignalRStatus status) {
    if (mounted) state = status;
  }
}
