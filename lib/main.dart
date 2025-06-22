import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/plant_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/settings_screen.dart';
import 'helpers/cache_helper.dart';
import 'helpers/network_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await CacheHelper.initialize();
    NetworkHelper.initialize();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _currentStep = '네트워크 연결 확인 중...';
      });

      await NetworkHelper.checkConnection();

      setState(() {
        _currentStep = '설정 초기화 중...';
      });

      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);

      await settingsProvider.initializeSettings();

      setState(() {
        _currentStep = '식물 프로파일 로드 중...';
      });

      await plantProvider.initialize();

      setState(() {
        _isInitialized = true;
        _currentStep = '완료';
      });

    } catch (e) {
      setState(() {
        _initError = e.toString();
        _currentStep = '초기화 실패';
      });
    }
  }

  void _retryInitialization() {
    setState(() {
      _initError = null;
      _isInitialized = false;
      _currentStep = '다시 시도 중...';
    });

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
                ElevatedButton.icon(
                  onPressed: _retryInitialization,
                  icon: Icon(Icons.refresh),
                  label: Text('다시 시도'),
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
              if (!NetworkHelper.isOnline) ...[
                SizedBox(height: 32),
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

class _SmartFarmAppState extends State<SmartFarmApp> {
  final List<Widget> _screens = [
    HomeScreen(),
    HistoryScreen(),
    NotificationScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<NavigationProvider, PlantProvider>(
      builder: (context, navigationProvider, plantProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '스마트팜',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
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
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: NetworkHelper.isOnline
                    ? () async {
                  if (plantProvider.hasPlant) {
                    await plantProvider.loadPlantData();
                  }
                }
                    : null,
                tooltip: NetworkHelper.isOnline ? '새로고침' : '오프라인 상태',
              ),
            ],
          ),
          body: IndexedStack(
            index: navigationProvider.currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
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