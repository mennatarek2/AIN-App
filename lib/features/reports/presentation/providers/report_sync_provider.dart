import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../my_reports/presentation/providers/my_reports_provider.dart';
import 'report_data_providers.dart';

/// Bootstraps report data synchronization with network connectivity.
///
/// When the device comes online, refreshes the My Reports list from the API.
/// With the new API-backed provider, there is no local offline queue to sync —
/// reports are submitted directly to the server.
final reportSyncBootstrapProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<bool>>(connectivityStatusProvider, (previous, next) {
    final wasOnline = previous?.valueOrNull ?? false;
    final isOnline = next.valueOrNull ?? false;

    if (!wasOnline && isOnline) {
      // When coming back online, refresh the my reports list.
      unawaited(ref.read(myReportsProvider.notifier).refresh());
    }
  });
});
