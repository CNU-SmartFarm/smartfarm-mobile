import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'notification_service.dart';
import '../models/plant.dart';
import '../models/plant_species.dart';
import '../models/sensor_data.dart';

class BackgroundMonitoringService {
  // 싱글톤 인스턴스
  static final BackgroundMonitoringService _instance = BackgroundMonitoringService._internal();
  factory BackgroundMonitoringService() => _instance;
  BackgroundMonitoringService._internal();

  // 백그라운드 서비스 인스턴스
  final FlutterBackgroundService _service = FlutterBackgroundService();

  // 서비스 상태 변수
  bool _isServiceInitialized = false;
  bool _isServiceRunning = false;

  // 서비스 초기화
  Future<void> init() async {
    if (_isServiceInitialized) return;

    // 백그라운드 서비스 설정
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'plant_monitor_service',
        initialNotificationTitle: '식물 모니터링',
        initialNotificationContent: '식물 환경을 모니터링 중입니다',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );

    _isServiceInitialized = true;
  }

  // 서비스 시작
  Future<bool> startService() async {
    if (!_isServiceInitialized) await init();

    _isServiceRunning = await _service.startService();
    return _isServiceRunning;
  }

  // 서비스 중지 - 수정된 부분
  Future<bool> stopService() async {
    if (!_isServiceInitialized) return false;

    // 서비스 중지 명령 전송
    _service.invoke('stopService');

    // 상태 변수 업데이트
    _isServiceRunning = false;

    // 서비스가 중지되었음을 반환
    return true;
  }

  // 서비스 실행 상태 확인
  Future<bool> isServiceRunning() async {
    if (!_isServiceInitialized) await init();

    _isServiceRunning = await _service.isRunning();
    return _isServiceRunning;
  }

  // 서비스 시작 시 자동 실행 설정
  Future<void> setAutoStart(bool autoStart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('background_service_autostart', autoStart);
  }

  // 서비스 시작 시 자동 실행 여부 확인
  Future<bool> getAutoStart() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('background_service_autostart') ?? false;
  }

  // Android/iOS 백그라운드 서비스 진입점
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    // 디버그용 로그
    DartPluginRegistrant.ensureInitialized();

    // 서비스가 안드로이드인 경우 포그라운드 서비스 실행
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    // 서비스 상태 콜백 등록
    service.on('setAsForeground').listen((event) {
      if (service is AndroidServiceInstance) {
        service.setAsForegroundService();
      }
    });

    service.on('setAsBackground').listen((event) {
      if (service is AndroidServiceInstance) {
        service.setAsBackgroundService();
      }
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // 정기적인 모니터링 시작
    Timer.periodic(const Duration(minutes: 15), (timer) async {
      // 알림 서비스 초기화
      final notificationService = NotificationService();
      await notificationService.init();

      // 알림이 비활성화 상태인지 확인
      if (!(await notificationService.isNotificationEnabled())) {
        return;
      }

      try {
        // API 서비스 생성
        final apiService = ApiService();

        // 식물 종 정보 가져오기
        final List<PlantSpecies> species = await apiService.getSpecies();
        // 식물 목록 가져오기
        final List<Plant> plants = await apiService.getPlants();

        for (final plant in plants) {
          // 각 식물의 최신 센서 데이터 가져오기
          final SensorData? latestData = await apiService.getLatestData(plant.id);

          if (latestData != null) {
            // 해당 식물 종 정보 찾기
            final PlantSpecies? plantSpecies = species.firstWhere(
                  (s) => s.id == plant.speciesId,
              orElse: () => null as PlantSpecies,
            );

            if (plantSpecies != null) {
              // 최신 데이터로 식물 정보 업데이트
              final updatedPlant = plant.updateWithLatestData(latestData);

              // 환경 적합성 확인 및 알림 메시지 생성
              final alertMessage = updatedPlant.generateAlertMessage(plantSpecies);

              // 알림이 필요한 경우 표시
              if (alertMessage != null && alertMessage.isNotEmpty) {
                await notificationService.showPlantNotification(
                  title: '식물 케어 알림',
                  message: alertMessage,
                  payload: plant.id,
                );
              }
            }
          }
        }
      } catch (e) {
        print('백그라운드 모니터링 오류: $e');
      }

      // 서비스가 아직 실행 중인지 알림
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: '식물 모니터링',
          content: '마지막 확인: ${DateTime.now().toString().substring(0, 16)}',
        );
      }

      // 서비스 상태 업데이트
      service.invoke('update', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  // iOS 백그라운드 서비스 핸들러
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    // iOS에서는 작업량을 최소화하고 true 반환
    return true;
  }
}