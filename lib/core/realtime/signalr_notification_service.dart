import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../features/notifications/data/models/notification_model.dart';
import '../network/api_config.dart';

class SignalRNotificationService {
  HubConnection? _hub;

  final _incoming = StreamController<NotificationModel>.broadcast();
  final _unreadCount = StreamController<int>.broadcast();

  Stream<NotificationModel> get onNotification => _incoming.stream;
  Stream<int> get onUnreadCount => _unreadCount.stream;

  bool get isConnected => _hub?.state == HubConnectionState.Connected;

  Future<void> connect(Future<String> Function() getToken) async {
    await disconnect();

    _hub = HubConnectionBuilder()
        .withUrl(
          '${ApiConfig.baseUrl}/hub/notifications',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => await getToken(),
            transport: HttpTransportType.WebSockets,
          ),
        )
        .withAutomaticReconnect(
          retryDelays: [2000, 5000, 10000, 30000],
        )
        .build();

    _hub!.on('ReceiveNotification', (args) {
      if (args == null || args.isEmpty) return;
      try {
        final raw = args[0];
        final map = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from(raw as Map);
        _incoming.add(NotificationModel.fromJson(map));
      } catch (e) {
        debugPrint(
          '[SignalR Notifications] ReceiveNotification parse error: $e',
        );
      }
    });

    _hub!.on('UpdateUnreadCount', (args) {
      if (args == null || args.isEmpty) return;
      final count = args[0];
      if (count is int) {
        _unreadCount.add(count);
      } else {
        _unreadCount.add(int.tryParse(count.toString()) ?? 0);
      }
    });

    await _hub!.start();
    debugPrint('[SignalR Notifications] Connected.');
  }

  Future<void> disconnect() async {
    try {
      await _hub?.stop();
    } catch (_) {}
    _hub = null;
  }

  void dispose() {
    _incoming.close();
    _unreadCount.close();
    disconnect();
  }
}

final signalRNotificationServiceProvider =
    Provider<SignalRNotificationService>((ref) {
  final service = SignalRNotificationService();
  ref.onDispose(service.dispose);
  return service;
});
