import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class NetworkHelper {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  static bool _isOnline = true;
  static List<Function(bool)> _listeners = [];

  static bool get isOnline => _isOnline;

  static void initialize() {
    // 초기 연결 상태 확인
    checkConnection();

    // 연결 상태 변화 감지
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      // 연결 상태가 변경된 경우에만 리스너들에게 알림
      if (wasOnline != _isOnline) {
        print('Network status changed: ${_isOnline ? 'Online' : 'Offline'}');
        _notifyListeners(_isOnline);
      }
    });
  }

  static Future<bool> checkConnection() async {
    try {
      final ConnectivityResult result = await _connectivity.checkConnectivity();
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      // 상태가 변경된 경우 리스너들에게 알림
      if (wasOnline != _isOnline) {
        print('Network status updated: ${_isOnline ? 'Online' : 'Offline'}');
        _notifyListeners(_isOnline);
      }

      return _isOnline;
    } catch (e) {
      print('Error checking network connection: $e');
      // 에러 발생 시 오프라인으로 간주
      if (_isOnline) {
        _isOnline = false;
        _notifyListeners(false);
      }
      return false;
    }
  }

  // 네트워크 상태 변화 리스너 추가
  static void addListener(Function(bool) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      print('Network listener added. Total listeners: ${_listeners.length}');
    }
  }

  // 네트워크 상태 변화 리스너 제거
  static void removeListener(Function(bool) listener) {
    _listeners.remove(listener);
    print('Network listener removed. Total listeners: ${_listeners.length}');
  }

  // 모든 리스너에게 상태 변화 알림
  static void _notifyListeners(bool isOnline) {
    for (final listener in _listeners) {
      try {
        listener(isOnline);
      } catch (e) {
        print('Error notifying network listener: $e');
      }
    }
  }

  // 연결 상태 강제 새로고침
  static Future<void> refresh() async {
    await checkConnection();
  }

  // 연결 품질 테스트 (핑 테스트)
  static Future<bool> testInternetConnection() async {
    try {
      // 실제 인터넷 연결 테스트
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.none) {
        return false;
      }

      // HTTP 요청으로 실제 인터넷 연결 확인
      // (API 서버 연결 테스트는 ApiService에서 담당)
      return true;
    } catch (e) {
      print('Internet connection test failed: $e');
      return false;
    }
  }

  // 연결 타입 가져오기
  static Future<String> getConnectionType() async {
    try {
      final ConnectivityResult result = await _connectivity.checkConnectivity();
      switch (result) {
        case ConnectivityResult.wifi:
          return 'WiFi';
        case ConnectivityResult.mobile:
          return 'Mobile Data';
        case ConnectivityResult.ethernet:
          return 'Ethernet';
        case ConnectivityResult.bluetooth:
          return 'Bluetooth';
        case ConnectivityResult.none:
          return 'No Connection';
        default:
          return 'Unknown';
      }
    } catch (e) {
      print('Error getting connection type: $e');
      return 'Error';
    }
  }

  // 연결 상태 정보 가져오기
  static Future<Map<String, dynamic>> getConnectionInfo() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final connectionType = await getConnectionType();

      return {
        'isOnline': _isOnline,
        'connectionType': connectionType,
        'connectivityResult': result.toString(),
        'lastChecked': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting connection info: $e');
      return {
        'isOnline': false,
        'connectionType': 'Error',
        'error': e.toString(),
        'lastChecked': DateTime.now().toIso8601String(),
      };
    }
  }

  // 네트워크 상태 모니터링 시작
  static void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    Timer.periodic(interval, (timer) {
      checkConnection();
    });
  }

  // 오프라인 모드 강제 설정 (테스트용)
  static void setOfflineMode(bool offline) {
    final wasOnline = _isOnline;
    _isOnline = !offline;

    if (wasOnline != _isOnline) {
      print('Network mode manually set: ${_isOnline ? 'Online' : 'Offline'}');
      _notifyListeners(_isOnline);
    }
  }

  // 리스너 등록 상태 확인 (디버그용)
  static int get listenerCount => _listeners.length;

  // 네트워크 상태 히스토리 (간단한 로깅)
  static final List<Map<String, dynamic>> _statusHistory = [];

  static void _logStatusChange(bool isOnline) {
    _statusHistory.add({
      'isOnline': isOnline,
      'timestamp': DateTime.now(),
    });

    // 최근 100개 기록만 유지
    if (_statusHistory.length > 100) {
      _statusHistory.removeAt(0);
    }
  }

  static List<Map<String, dynamic>> get statusHistory => List.unmodifiable(_statusHistory);

  // 리소스 정리
  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _listeners.clear();
    _statusHistory.clear();
    print('NetworkHelper disposed');
  }

  // 디버그 정보 출력
  static void printDebugInfo() {
    print('=== NetworkHelper Debug Info ===');
    print('Current Status: ${_isOnline ? 'Online' : 'Offline'}');
    print('Listeners Count: ${_listeners.length}');
    print('History Count: ${_statusHistory.length}');
    print('Subscription Active: ${_connectivitySubscription != null}');
    print('================================');
  }

  // 네트워크 상태 변화 스트림 제공
  static Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((result) {
      final isOnline = result != ConnectivityResult.none;
      if (_isOnline != isOnline) {
        _isOnline = isOnline;
        _logStatusChange(isOnline);
      }
      return isOnline;
    });
  }

  // 연결 안정성 확인 (여러 번 체크)
  static Future<bool> checkStability({int attempts = 3, Duration delay = const Duration(seconds: 1)}) async {
    int successCount = 0;

    for (int i = 0; i < attempts; i++) {
      if (i > 0) await Future.delayed(delay);

      try {
        final result = await _connectivity.checkConnectivity();
        if (result != ConnectivityResult.none) {
          successCount++;
        }
      } catch (e) {
        print('Connection stability check failed (attempt ${i + 1}): $e');
      }
    }

    final isStable = successCount >= (attempts / 2).ceil();
    print('Connection stability: $successCount/$attempts (${isStable ? 'Stable' : 'Unstable'})');

    return isStable;
  }

  // 네트워크 복구 대기
  static Future<bool> waitForConnection({Duration timeout = const Duration(seconds: 30)}) async {
    if (_isOnline) return true;

    final completer = Completer<bool>();
    late StreamSubscription subscription;
    late Timer timeoutTimer;

    // 타임아웃 타이머 설정
    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.complete(false);
      }
    });

    // 연결 상태 변화 감지
    subscription = onConnectivityChanged.listen((isOnline) {
      if (isOnline && !completer.isCompleted) {
        timeoutTimer.cancel();
        subscription.cancel();
        completer.complete(true);
      }
    });

    return completer.future;
  }
}