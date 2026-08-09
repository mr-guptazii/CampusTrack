import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around connectivity_plus exposing a simple online/offline
/// stream. Providers listen to this to trigger a sync when the device comes
/// back online.
class ConnectivityService {
  ConnectivityService._internal() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    });
  }

  static final ConnectivityService instance = ConnectivityService._internal();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChange => _controller.stream;

  late final StreamSubscription _sub;

  Future<bool> checkNow() async {
    final results = await Connectivity().checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);
    return _isOnline;
  }

  void dispose() {
    _sub.cancel();
    _controller.close();
  }
}
