import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'providers/plant_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/settings_screen.dart';
import 'helpers/cache_helper.dart';
import 'helpers/network_helper.dart';
import 'helpers/sync_helper.dart';
import 'helpers/notification_helper.dart';
import 'helpers/permission_helper.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 기본 헬퍼들 초기화
    await CacheHelper.initialize();
    NetworkHelper.initialize();

    // 권한 확인
    await PermissionHelper.requestNotificationPermission();

    runApp(MyApp());
  } catch (e) {
    print('앱 초기화 오류: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => PlantProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: '스마트팜',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(settingsProvider.theme),
            home: AppInitializer(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(String themeMode) {
    bool isDark = themeMode == 'dark';

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primarySwatch: Colors.green,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(0xFF4CAF50),
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: isDark ? Color(0xFF121212) : Color(0xFFF8F9FA),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF4CAF50),
        unselectedItemColor: isDark ? Color(0xFF999999) : Color(0xFF666666),
        backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '스마트팜 - 오류',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  '앱 초기화 실패',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // 앱 재시작
                    main();
                  },
                  child: Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String? _initError;
  String _currentStep = '초기화 중...';

  @override
  void initState() {
    super.initState();
    // 빌드 완료 후에 초기화 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _currentStep = '네트워크 연결 확인 중...';
      });

      // 네트워크 연결 확인
      final isConnected = await NetworkHelper.checkConnection();

      if (isConnected) {
        setState(() {
          _currentStep = 'API 서버 연결 확인 중...';
        });

        // API 서버 연결 테스트
        final apiConnected = await ApiService.testConnection();
        if (!apiConnected) {
          print('Warning: API server connection failed, running in offline mode');
        }
      }

      setState(() {
        _currentStep = '설정 초기화 중...';
      });

      // Provider들을 listen: false로 가져와서 빌드 중 상태 변경 방지
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);

      // 설정 초기화
      await settingsProvider.initializeSettings();

      setState(() {
        _currentStep = '식물 프로파일 로드 중...';
      });

      // 식물 데이터 초기화
      await plantProvider.initialize();

      setState(() {
        _currentStep = '동기화 시작 중...';
      });

      // 네트워크 상태 변화 리스너 등록
      NetworkHelper.initialize();

      // 동기화 시작
      if (NetworkHelper.isOnline) {
        SyncHelper.startPeriodicSync();

        // 초기 동기화 실행
        unawaited(SyncHelper.syncData());
      }

      // 네트워크 상태 변화 감지
      _setupNetworkListener();

      setState(() {
        _isInitialized = true;
        _currentStep = '완료';
      });

    } catch (e) {
      setState(() {
        _initError = e.toString();
        _currentStep = '초기화 실패';
      });
      print('앱 초기화 오류: $e');
    }
  }

  void _setupNetworkListener() {
    // 네트워크 상태 변화 감지 및 동기화
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      NetworkHelper.checkConnection().then((isOnline) {
        if (isOnline && !SyncHelper.isSyncing) {
          SyncHelper.onConnectionChanged(true);
        }
      });
    });
  }

  void _retryInitialization() {
    setState(() {
      _initError = null;
      _isInitialized = false;
      _currentStep = '다시 시도 중...';
    });

    // 약간의 지연 후 다시 초기화 시도
    Future.delayed(Duration(milliseconds: 500), () {
      _initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  '초기화 실패',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _retryInitialization,
                      icon: Icon(Icons.refresh),
                      label: Text('다시 시도'),
                    ),
                    SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        // 오프라인 모드로 시작
                        setState(() {
                          _initError = null;
                          _isInitialized = true;
                          _currentStep = '오프라인 모드';
                        });
                      },
                      icon: Icon(Icons.wifi_off),
                      label: Text('오프라인 모드'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  '네트워크 연결을 확인해주세요',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.eco_outlined,
                  size: 50,
                  color: Color(0xFF66BB6A),
                ),
              ),
              SizedBox(height: 32),
              Text(
                '스마트팜',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '가정용 식물 관리 시스템',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
              SizedBox(height: 48),
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF66BB6A)),
                      backgroundColor: Color(0xFFE8F5E8),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _currentStep,
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              if (!NetworkHelper.isOnline) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border.all(color: Colors.orange[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.orange[700], size: 16),
                      SizedBox(width: 8),
                      Text(
                        '오프라인 모드',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SmartFarmApp();
  }
}

class SmartFarmApp extends StatefulWidget {
  @override
  _SmartFarmAppState createState() => _SmartFarmAppState();
}

class _SmartFarmAppState extends State<SmartFarmApp> with WidgetsBindingObserver {
  final List<Widget> _screens = [
    HomeScreen(),
    HistoryScreen(),
    NotificationScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SyncHelper.stopPeriodicSync();
    NetworkHelper.dispose();
    ApiService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
      // 앱이 다시 활성화되면 네트워크 상태 확인 및 동기화
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
      // 앱이 백그라운드로 갈 때 동기화 중지
        SyncHelper.stopPeriodicSync();
        break;
      default:
        break;
    }
  }

  Future<void> _onAppResumed() async {
    try {
      // 네트워크 상태 다시 확인
      final isOnline = await NetworkHelper.checkConnection();

      if (isOnline) {
        // 온라인이면 동기화 재시작
        SyncHelper.startPeriodicSync();

        // 즉시 동기화 실행
        unawaited(SyncHelper.syncData());

        // PlantProvider 데이터도 새로고침
        final plantProvider = Provider.of<PlantProvider>(context, listen: false);
        if (plantProvider.hasPlant) {
          unawaited(plantProvider.loadPlantData());
        }
      }
    } catch (e) {
      print('App resume error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NavigationProvider, PlantProvider>(
      builder: (context, navigationProvider, plantProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '돌보미 스마트팜 v1.0',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              // 네트워크 상태 표시
              if (!NetworkHelper.isOnline) ...[
                Tooltip(
                  message: '오프라인 모드',
                  child: Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.wifi_off,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                ),
              ],

              // 동기화 상태 표시
              if (SyncHelper.isSyncing) ...[
                Tooltip(
                  message: '동기화 중',
                  child: Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              ],

              // 수동 새로고침 버튼
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: NetworkHelper.isOnline && !SyncHelper.isSyncing
                    ? () async {
                  // 수동 동기화
                  try {
                    await SyncHelper.manualSync();
                    if (plantProvider.hasPlant) {
                      await plantProvider.loadPlantData();
                    }
                    NotificationHelper.showSuccessSnackBar(context, '동기화가 완료되었습니다.');
                  } catch (e) {
                    NotificationHelper.showErrorSnackBar(context, '동기화에 실패했습니다: $e');
                  }
                }
                    : null,
                tooltip: NetworkHelper.isOnline
                    ? (SyncHelper.isSyncing ? '동기화 중...' : '수동 동기화')
                    : '오프라인 상태',
              ),
            ],
          ),
          body: IndexedStack(
            index: navigationProvider.currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: navigationProvider.currentIndex,
            onTap: (index) {
              navigationProvider.setIndex(index);
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: '홈',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.trending_up),
                label: '데이터',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    Icon(Icons.notifications),
                    if (plantProvider.unreadNotificationsCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${plantProvider.unreadNotificationsCount > 99 ? '99+' : plantProvider.unreadNotificationsCount}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: '알림',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: '설정',
              ),
            ],
          ),
        );
      },
    );
  }
}