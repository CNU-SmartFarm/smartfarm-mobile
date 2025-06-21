import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'network_helper.dart';
import 'cache_helper.dart';
import 'database_helper.dart';
import '../services/api_service.dart';
import '../models/app_models.dart';

class SyncHelper {
  static Timer? _syncTimer;
  static bool _isSyncing = false;
  static final DatabaseHelper _dbHelper = DatabaseHelper();

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
      print('데이터 동기화 시작...');

      // 1. 로컬 변경사항을 서버로 업로드
      await _uploadLocalChanges();

      // 2. 서버에서 최신 데이터 다운로드
      await _downloadServerData();

      // 3. 동기화 완료 후 마지막 동기화 시간 업데이트
      await CacheHelper.setInt(CacheHelper.LAST_SYNC_TIME, DateTime.now().millisecondsSinceEpoch);

      print('데이터 동기화 완료');
    } catch (e) {
      print('동기화 오류: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // 로컬 변경사항을 서버로 업로드
  static Future<void> _uploadLocalChanges() async {
    try {
      // lastSynced가 0인 데이터들을 찾아서 서버로 업로드
      final db = await _dbHelper.database;

      // 동기화되지 않은 식물 데이터 업로드
      final unSyncedPlants = await db.query(
        'plants',
        where: 'lastSynced = ?',
        whereArgs: [0],
      );

      for (final plantData in unSyncedPlants) {
        try {
          final plant = Plant.fromJson(plantData);

          if (plantData['id'].toString().length > 10) {
            // 로컬에서 생성된 ID (timestamp)인 경우 새로 등록
            final registeredPlant = await ApiService.registerPlant(plant);
            if (registeredPlant != null) {
              // 새로운 ID로 업데이트
              await db.update(
                'plants',
                {
                  'id': registeredPlant.id,
                  'lastSynced': DateTime.now().millisecondsSinceEpoch,
                },
                where: 'id = ?',
                whereArgs: [plant.id],
              );
            }
          } else {
            // 서버 ID인 경우 업데이트
            await ApiService.updatePlant(plant.id, plant);
            await db.update(
              'plants',
              {'lastSynced': DateTime.now().millisecondsSinceEpoch},
              where: 'id = ?',
              whereArgs: [plant.id],
            );
          }
        } catch (e) {
          print('식물 데이터 업로드 실패: $e');
        }
      }

      // 동기화되지 않은 센서 데이터 업로드
      final unSyncedSensorData = await db.query(
        'sensor_data',
        where: 'lastSynced = ?',
        whereArgs: [0],
      );

      for (final sensorDataMap in unSyncedSensorData) {
        try {
          final sensorData = SensorData.fromJson(sensorDataMap);
          final success = await ApiService.uploadSensorData(sensorData.plantId, sensorData);

          if (success) {
            await db.update(
              'sensor_data',
              {'lastSynced': DateTime.now().millisecondsSinceEpoch},
              where: 'id = ?',
              whereArgs: [sensorData.id],
            );
          }
        } catch (e) {
          print('센서 데이터 업로드 실패: $e');
        }
      }

      // 동기화되지 않은 설정 데이터 업로드
      final unSyncedSettings = await db.query(
        'settings',
        where: 'lastSynced = ?',
        whereArgs: [0],
      );

      for (final settingsData in unSyncedSettings) {
        try {
          final settings = Settings.fromJson(settingsData);
          final updatedSettings = await ApiService.updateSettings(settings);

          if (updatedSettings != null) {
            await db.update(
              'settings',
              {'lastSynced': DateTime.now().millisecondsSinceEpoch},
              where: 'userId = ?',
              whereArgs: [settings.userId],
            );
          }
        } catch (e) {
          print('설정 데이터 업로드 실패: $e');
        }
      }

    } catch (e) {
      print('로컬 변경사항 업로드 실패: $e');
    }
  }

  // 서버에서 최신 데이터 다운로드
  static Future<void> _downloadServerData() async {
    try {
      // 현재 식물 ID 가져오기
      final currentPlantId = CacheHelper.getString(CacheHelper.CURRENT_PLANT_ID);

      if (currentPlantId != null && currentPlantId.isNotEmpty) {
        // 식물 정보 동기화
        await _syncPlantData(currentPlantId);

        // 센서 데이터 동기화
        await _syncSensorData(currentPlantId);

        // 알림 데이터 동기화
        await _syncNotifications(currentPlantId);
      }

      // 설정 데이터 동기화
      await _syncSettings();

      // 식물 프로파일 동기화
      await _syncPlantProfiles();

    } catch (e) {
      print('서버 데이터 다운로드 실패: $e');
    }
  }

  // 식물 데이터 동기화
  static Future<void> _syncPlantData(String plantId) async {
    try {
      final plant = await ApiService.getPlant(plantId);
      if (plant != null) {
        final plantData = plant.toJson();
        plantData['lastSynced'] = DateTime.now().millisecondsSinceEpoch;
        await _dbHelper.insertPlant(plantData);
      }
    } catch (e) {
      print('식물 데이터 동기화 실패: $e');
    }
  }

  // 센서 데이터 동기화
  static Future<void> _syncSensorData(String plantId) async {
    try {
      // 최신 센서 데이터 가져오기
      final currentSensorData = await ApiService.getCurrentSensorData(plantId);
      if (currentSensorData != null) {
        final sensorDataMap = currentSensorData.toJson();
        sensorDataMap['lastSynced'] = DateTime.now().millisecondsSinceEpoch;
        await _dbHelper.insertSensorData(sensorDataMap);
      }

      // 과거 센서 데이터 동기화 (최근 7일)
      final historicalData = await ApiService.getHistoricalData(plantId, '7d');
      for (final dataPoint in historicalData) {
        try {
          // HistoricalDataPoint를 SensorData 형태로 변환하여 저장
          final sensorData = SensorData(
            id: dataPoint.id,
            plantId: dataPoint.plantId,
            temperature: dataPoint.temperature,
            humidity: dataPoint.humidity,
            soilMoisture: dataPoint.soilMoisture,
            light: dataPoint.light,
            timestamp: DateTime.parse('${dataPoint.date}T${dataPoint.time.toString().padLeft(2, '0')}:00:00'),
          );

          final sensorDataMap = sensorData.toJson();
          sensorDataMap['lastSynced'] = DateTime.now().millisecondsSinceEpoch;
          await _dbHelper.insertSensorData(sensorDataMap);
        } catch (e) {
          print('개별 센서 데이터 저장 실패: $e');
        }
      }
    } catch (e) {
      print('센서 데이터 동기화 실패: $e');
    }
  }

  // 알림 데이터 동기화
  static Future<void> _syncNotifications(String plantId) async {
    try {
      final notifications = await ApiService.getNotifications(plantId, limit: 50);
      for (final notification in notifications) {
        final notificationData = notification.toJson();
        notificationData['lastSynced'] = DateTime.now().millisecondsSinceEpoch;
        await _dbHelper.insertNotification(notificationData);
      }
    } catch (e) {
      print('알림 데이터 동기화 실패: $e');
    }
  }

  // 설정 데이터 동기화
  static Future<void> _syncSettings() async {
    try {
      final settings = await ApiService.getSettings();
      if (settings != null) {
        final settingsData = settings.toJson();
        settingsData['lastSynced'] = DateTime.now().millisecondsSinceEpoch;
        await _dbHelper.insertOrUpdateSettings(settingsData);

        // 캐시에도 저장
        await CacheHelper.setJson(CacheHelper.USER_SETTINGS, settings.toJson());
      }
    } catch (e) {
      print('설정 데이터 동기화 실패: $e');
    }
  }

  // 식물 프로파일 동기화
  static Future<void> _syncPlantProfiles() async {
    try {
      final plantProfiles = await ApiService.getPlantProfiles();
      if (plantProfiles.isNotEmpty) {
        // 캐시에 저장
        await CacheHelper.setJson(CacheHelper.PLANT_PROFILES_CACHE, {
          'data': plantProfiles.map((profile) => profile.toJson()).toList(),
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('식물 프로파일 동기화 실패: $e');
    }
  }

  // 수동 동기화 (사용자가 당겨서 새로고침할 때)
  static Future<bool> manualSync() async {
    if (_isSyncing) return false;

    if (!NetworkHelper.isOnline) {
      print('오프라인 상태에서는 동기화할 수 없습니다.');
      return false;
    }

    await syncData();
    return true;
  }

  // 특정 식물 데이터만 동기화
  static Future<bool> syncPlantOnly(String plantId) async {
    if (!NetworkHelper.isOnline) return false;

    try {
      await _syncPlantData(plantId);
      await _syncSensorData(plantId);
      await _syncNotifications(plantId);
      return true;
    } catch (e) {
      print('식물 데이터 동기화 실패: $e');
      return false;
    }
  }

  // 연결 상태 변경 시 동기화
  static Future<void> onConnectionChanged(bool isOnline) async {
    if (isOnline && !_isSyncing) {
      // 온라인 상태로 변경되면 즉시 동기화 시도
      await Future.delayed(Duration(seconds: 2)); // 안정화 대기
      await syncData();
    }
  }

  // 동기화 상태 확인
  static Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final db = await _dbHelper.database;

      // 동기화되지 않은 데이터 개수 확인
      final unSyncedPlantsResult = await db.rawQuery('SELECT COUNT(*) as count FROM plants WHERE lastSynced = 0');
      final unSyncedPlantsCount = unSyncedPlantsResult.first['count'] as int;

      final unSyncedSensorDataResult = await db.rawQuery('SELECT COUNT(*) as count FROM sensor_data WHERE lastSynced = 0');
      final unSyncedSensorDataCount = unSyncedSensorDataResult.first['count'] as int;

      final unSyncedNotificationsResult = await db.rawQuery('SELECT COUNT(*) as count FROM notifications WHERE lastSynced = 0');
      final unSyncedNotificationsCount = unSyncedNotificationsResult.first['count'] as int;

      final lastSyncTime = getLastSyncTime();

      return {
        'unSyncedPlantsCount': unSyncedPlantsCount,
        'unSyncedSensorDataCount': unSyncedSensorDataCount,
        'unSyncedNotificationsCount': unSyncedNotificationsCount,
        'lastSyncTime': lastSyncTime,
        'hasUnSyncedData': (unSyncedPlantsCount + unSyncedSensorDataCount + unSyncedNotificationsCount) > 0,
        'isSyncing': _isSyncing,
      };
    } catch (e) {
      print('동기화 상태 확인 실패: $e');
      return {
        'error': e.toString(),
        'isSyncing': _isSyncing,
      };
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

  // 강제 동기화 (모든 데이터를 서버에서 다시 가져옴)
  static Future<void> forceSyncFromServer() async {
    if (!NetworkHelper.isOnline) {
      throw Exception('네트워크 연결이 필요합니다.');
    }

    _isSyncing = true;
    try {
      print('강제 동기화 시작...');

      // 로컬 데이터 초기화 (선택적)
      // await _clearLocalData();

      // 서버에서 모든 데이터 다시 가져오기
      await _downloadServerData();

      await CacheHelper.setInt(CacheHelper.LAST_SYNC_TIME, DateTime.now().millisecondsSinceEpoch);

      print('강제 동기화 완료');
    } catch (e) {
      print('강제 동기화 실패: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  // 로컬 데이터 초기화 (주의: 동기화되지 않은 데이터 손실 가능)
  static Future<void> _clearLocalData() async {
    try {
      final db = await _dbHelper.database;

      await db.delete('sensor_data');
      await db.delete('notifications');
      // plants 테이블은 유지 (중요한 데이터이므로)

      print('로컬 데이터 초기화 완료');
    } catch (e) {
      print('로컬 데이터 초기화 실패: $e');
    }
  }
}