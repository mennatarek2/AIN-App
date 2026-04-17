import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<bool> get onlineStatusStream {
    return _connectivity.onConnectivityChanged.map(_isConnected).distinct();
  }

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return _isConnected(result);
  }

  bool _isConnected(dynamic result) {
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }

    if (result is List<ConnectivityResult>) {
      return result.any((entry) => entry != ConnectivityResult.none);
    }

    return false;
  }
}
