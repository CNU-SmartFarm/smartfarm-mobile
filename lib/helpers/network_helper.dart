import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class NetworkHelper {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  static bool _isOnline = true;

  static bool get isOnline => _isOnline;

  static void initialize() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  static Future<bool> checkConnection() async {
    final ConnectivityResult result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    return _isOnline;
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
  }
}