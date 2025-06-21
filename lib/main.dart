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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 헬퍼들 초기화
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
      // Provider들을 listen: false로 가져와서 빌드 중 상태 변경 방지
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);

      // 설정 초기화
      await settingsProvider.initializeSettings();

      // 식물 프로파일 로드
      await plantProvider.loadPlantProfiles();

      // 네트워크 연결 확인
      await NetworkHelper.checkConnection();

      // 마지막 식물 ID 복원
      final lastPlantId = CacheHelper.getString(CacheHelper.CURRENT_PLANT_ID);
      if (lastPlantId != null && lastPlantId.isNotEmpty) {
        // 실제 구현에서는 여기서 식물 정보를 로드해야 함
        // await plantProvider.loadPlant(lastPlantId);
      }

      // 동기화 시작
      SyncHelper.startPeriodicSync();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = e.toString();
        });
      }
      print('앱 초기화 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        body: Center(
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _initError = null;
                    _isInitialized = false;
                  });
                  // 다시 초기화 시도
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _initializeApp();
                  });
                },
                child: Text('다시 시도'),
              ),
            ],
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
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.eco_outlined,
                  size: 40,
                  color: Color(0xFF66BB6A),
                ),
              ),
              SizedBox(height: 24),
              Text(
                '스마트팜',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '가정용 식물 관리 시스템',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                '앱을 초기화하는 중...',
                style: TextStyle(color: Color(0xFF666666)),
              ),
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

class _SmartFarmAppState extends State<SmartFarmApp> {
  final List<Widget> _screens = [
    HomeScreen(),
    HistoryScreen(),
    NotificationScreen(),
    SettingsScreen(),
  ];

  @override
  void dispose() {
    SyncHelper.stopPeriodicSync();
    NetworkHelper.dispose();
    super.dispose();
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
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.wifi_off,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
              ],

              // 동기화 상태 표시
              if (SyncHelper.isSyncing) ...[
                Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ],
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
                            '${plantProvider.unreadNotificationsCount}',
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