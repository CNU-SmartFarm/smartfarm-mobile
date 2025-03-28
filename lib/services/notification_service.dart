import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  // 싱글톤 인스턴스
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // 알림 플러그인 인스턴스
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // 웹에서 사용 시 필요한 ScaffoldMessengerKey (웹 사용 안하면 제거 가능)
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // 초기화 완료 여부
  bool _initialized = false;

  // 알림 채널 ID와 이름
  static const String _channelId = 'plant_monitor';
  static const String _channelName = '식물 모니터링';
  static const String _channelDescription = '식물 환경 알림';

  // 알림 ID 카운터
  int _notificationIdCounter = 0;

  // 초기화 함수
  Future<void> init() async {
    if (_initialized) return;

    // Android용 초기화 설정
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS용 초기화 설정
    final DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // 초기화 시 권한 요청 안 함 (아래에서 별도 요청)
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // iOS 10 미만 디바이스 처리 (필요한 경우 로직 추가)
        print('onDidReceiveLocalNotification: id=$id, title=$title, body=$body, payload=$payload');
      },
    );

    // 플랫폼 별 초기화 설정 통합
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    // 알림 플러그인 초기화
    // 알림 탭 시 처리 로직은 initialize의 onDidReceiveNotificationResponse 콜백에서 처리
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // 알림 탭 시 처리 로직 (백그라운드/종료 상태에서도 호출될 수 있음)
        print('알림 탭 (onDidReceiveNotificationResponse): payload=${details.payload}, actionId=${details.actionId}');
        // 여기에 payload 기반 라우팅 등 추가 로직 구현
      },
      // 앱이 실행 중일 때 알림 수신 시 (iOS 10+)
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );

    // --- 권한 요청 로직 시작 ---
    await _requestPermissions();
    // --- 권한 요청 로직 끝 ---

    _initialized = true;
    print('NotificationService initialized.');
  }

  // 권한 요청 함수 분리
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      // iOS 권한 요청
      await _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      // Android 13+ (API 33) 알림 권한 요청
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // requestNotificationsPermission 사용 (v17+ 권장)
      // Android 13 미만에서는 항상 true를 반환함
      final bool? granted = await androidImplementation?.requestNotificationsPermission();

      print("Android Notification Permission Granted: ${granted ?? false}");

      // 참고: 정확한 시간 알림(Exact Alarms) 권한이 필요하다면 추가 요청
      // final bool? exactAlarmsGranted = await androidImplementation?.requestExactAlarmsPermission();
      // print("Android Exact Alarms Permission Granted: ${exactAlarmsGranted ?? false}");
      // 이 경우 AndroidManifest.xml에 SCHEDULE_EXACT_ALARM 또는 USE_EXACT_ALARM 권한 추가 필요
    }
  }

  // 알림 설정 상태 확인
  Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // SharedPreferences에 저장된 설정 값 확인
    return prefs.getBool('notifications_enabled') ?? true; // 기본값은 활성화
  }

  // 알림 활성화/비활성화 설정
  Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    print("Notification enabled status set to: $enabled");
    if (!enabled) {
      // 비활성화 시 예약된 알림 취소 등의 추가 로직 가능
      // await cancelAllNotifications();
    }
  }

  // 식물 알림 전송
  Future<void> showPlantNotification({
    required String title,
    required String message,
    String? payload, // 알림 탭 시 전달할 데이터
  }) async {
    // 설정에서 알림이 비활성화되어 있으면 보내지 않음
    if (!await isNotificationEnabled()) {
      print("Notifications are disabled by user settings. Skipping notification.");
      return;
    }

    // 초기화되지 않았으면 먼저 초기화 (init 호출 보장)
    if (!_initialized) {
      print("NotificationService not initialized yet. Initializing...");
      await init();
    }

    // Android 노티피케이션 상세 설정
    AndroidNotificationDetails androidDetails = const AndroidNotificationDetails(
      _channelId, // 채널 ID
      _channelName, // 채널 이름
      channelDescription: _channelDescription, // 채널 설명
      importance: Importance.high, // 중요도 높음 (헤드업 알림 표시 가능)
      priority: Priority.high, // 우선순위 높음
      ticker: 'ticker', // 상태 표시줄에 잠시 표시될 텍스트 (오래된 버전용)
      color: Colors.green, // 아이콘 배경색 등
      // sound: RawResourceAndroidNotificationSound('notification_sound'), // 커스텀 사운드 사용 시 (android/app/src/main/res/raw 폴더에 파일 필요)
      // largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), // 큰 아이콘 설정
    );

    // iOS 노티피케이션 상세 설정
    DarwinNotificationDetails iOSDetails = const DarwinNotificationDetails(
      presentAlert: true, // 알림 표시
      presentBadge: true, // 뱃지 표시
      presentSound: true, // 사운드 재생
      // sound: 'custom_sound.caf', // 커스텀 사운드 사용 시 (프로젝트에 포함 필요)
      // badgeNumber: 1, // 뱃지 숫자 지정 (필요 시 동적 관리)
    );

    // 플랫폼 별 설정 통합
    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // 알림 ID 생성 (고유해야 함, 필요 시 payload 등 기반으로 생성 가능)
    int id = _getNextNotificationId();

    print("Showing notification: id=$id, title=$title, message=$message, payload=$payload");

    // 알림 표시
    try {
      await _notifications.show(
        id,
        title,
        message,
        platformDetails,
        payload: payload, // 알림 탭 시 전달될 데이터
      );
    } catch (e) {
      print("Error showing notification: $e");
    }
  }

  // 겹치지 않는 알림 ID 생성 (간단 버전)
  int _getNextNotificationId() {
    // 실제 앱에서는 좀 더 견고한 ID 관리 방식 고려 (예: SharedPreferences 사용)
    _notificationIdCounter++;
    return _notificationIdCounter;
  }

  // 특정 ID의 알림 취소
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print("Cancelled notification with id: $id");
  }

  // 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print("Cancelled all notifications.");
  }
}

// 백그라운드에서 알림 탭 시 호출될 수 있는 최상위 함수 또는 static 함수
// (main.dart 또는 별도 파일에 두는 것이 더 일반적일 수 있음)
@pragma('vm:entry-point')
void _notificationTapBackground(NotificationResponse notificationResponse) {
  // handle action
  print('알림 탭 (Background - _notificationTapBackground): payload=${notificationResponse.payload}, actionId=${notificationResponse.actionId}');
  // 여기서 payload 기반으로 특정 로직 수행 가능 (예: 특정 화면으로 이동 준비)
  // 주의: 이 함수는 Isolate 환경에서 실행될 수 있으므로 Flutter 엔진/플러그인 직접 접근 제한적
}