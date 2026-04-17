import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../my_reports/presentation/providers/my_reports_provider.dart';
import 'report_data_providers.dart';

final reportSyncBootstrapProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<bool>>(connectivityStatusProvider, (previous, next) {
    final wasOnline = previous?.valueOrNull ?? false;
    final isOnline = next.valueOrNull ?? false;

    if (!wasOnline && isOnline) {
      unawaited(ref.read(myReportsProvider.notifier).syncPendingReports());
    }
  });

  // Run once on startup to sync pending reports if internet already exists.
  unawaited(ref.read(myReportsProvider.notifier).syncPendingReports());
});
