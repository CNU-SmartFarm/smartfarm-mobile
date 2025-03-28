import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/mock_api_service.dart'; // 테스트용 서비스 추가
import 'providers/plant_provider.dart';
import 'screens/home_screen.dart';

// 테스트 모드 설정
const bool TEST_MODE = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 알림 서비스 초기화
  final notificationService = NotificationService();
  await notificationService.init();

  // 백그라운드 서비스 초기화
  final backgroundService = BackgroundMonitoringService();
  await backgroundService.init();

  // 테스트 모드에서는 모의 API 서비스 초기화
  if (TEST_MODE) {
    final mockApiService = MockApiService();
    await mockApiService.init();
  }

  // 자동 시작 설정이 활성화된 경우 백그라운드 서비스 시작
  if (await backgroundService.getAutoStart()) {
    await backgroundService.startService();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PlantProvider(testMode: TEST_MODE),
        ),
      ],
      child: MaterialApp(
        title: '식물 원격 관리' + (TEST_MODE ? ' (테스트 모드)' : ''),
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
          // 앱 디자인 테마 설정
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: TEST_MODE, // 테스트 모드일 때만 디버그 배너 표시
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 잠시 후 메인 화면으로 이동
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 로고
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.eco,
                size: 70,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 24),

            // 앱 이름
            Text(
              TEST_MODE ? '식물 원격 관리 (테스트 모드)' : '식물 원격 관리',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),

            // 앱 설명
            Text(
              '당신의 식물을 언제 어디서나 관리하세요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 48),

            // 로딩 인디케이터
            const CircularProgressIndicator(),

            if (TEST_MODE) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: const Text(
                  '백엔드 API 없이 테스트 중입니다',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}