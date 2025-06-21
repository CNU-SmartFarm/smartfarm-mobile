import 'dart:async';
import 'network_helper.dart';
import 'cache_helper.dart';

class SyncHelper {
  static Timer? _syncTimer;
  static bool _isSyncing = false;

  static void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (timer) {
      if (!_isSyncing && NetworkHelper.isOnline) {
        syncData();
      }
    });
  }

  static Future<void> syncData() async {
    if (_isSyncing || !NetworkHelper.isOnline) return;

    _isSyncing = true;
    try {
      // 여기에 실제 동기화 로직 구현
      // 1. 로컬 변경사항을 서버로 업로드
      // 2. 서버에서 최신 데이터 다운로드
      // 3. 로컬 데이터베이스 업데이트

      print('데이터 동기화 시작...');

      // 동기화 완료 후 마지막 동기화 시간 업데이트
      await CacheHelper.setInt(CacheHelper.LAST_SYNC_TIME, DateTime.now().millisecondsSinceEpoch);

      print('데이터 동기화 완료');
    } catch (e) {
      print('동기화 오류: $e');
    } finally {
      _isSyncing = false;
    }
  }

  static void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  static bool get isSyncing => _isSyncing;

  static DateTime? getLastSyncTime() {
    final int? timestamp = CacheHelper.getInt(CacheHelper.LAST_SYNC_TIME);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
}