# 🌱 스마트팜 (SmartFarm)

가정용 식물 관리 시스템을 위한 Flutter 모바일 애플리케이션

## 📖 프로젝트 개요

스마트팜은 IoT 센서를 활용하여 실내 식물의 환경을 실시간으로 모니터링하고 관리할 수 있는 모바일 애플리케이션입니다. AI 기반 식물 인식, 센서 데이터 분석, 개인화된 알림 등의 기능을 제공합니다.

### 주요 기능

- 🤖 **AI 식물 인식**: 카메라로 식물을 촬영하여 자동 식별 및 등록
- 📊 **실시간 센서 모니터링**: 온도, 습도, 토양수분, 조도 실시간 추적
- 📈 **데이터 시각화**: 시간별/일별 환경 데이터 트렌드 분석
- 🔔 **스마트 알림**: 최적 환경 범위 이탈 시 즉시 알림
- ⚙️ **맞춤 설정**: 식물별 최적 환경 범위 개인화
- 🌐 **오프라인 지원**: 네트워크 연결 없이도 기본 기능 사용 가능

## 🏗️ 기술 스택

- **Frontend**: Flutter (Dart)
- **State Management**: Provider Pattern
- **HTTP Client**: http package
- **Charts**: fl_chart
- **Local Storage**: shared_preferences
- **Permissions**: permission_handler
- **Image Handling**: image_picker
- **Network Detection**: connectivity_plus

## 📁 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점 및 초기화
├── models/                            # 데이터 모델
│   ├── plant.dart                     # 식물 모델
│   ├── sensor_data.dart               # 센서 데이터 모델
│   ├── notification_item.dart         # 알림 모델
│   ├── historical_data_point.dart     # 과거 데이터 포인트 모델
│   ├── settings.dart                  # 설정 모델
│   ├── plant_profile.dart             # 식물 프로파일 모델
│   └── ai_identification_result.dart  # AI 인식 결과 모델
├── providers/                         # 상태 관리 (Provider)
│   ├── plant_provider.dart           # 식물 관련 상태 관리
│   ├── settings_provider.dart        # 설정 관련 상태 관리
│   └── navigation_provider.dart      # 네비게이션 상태 관리
├── services/                          # 외부 서비스
│   └── api_service.dart              # REST API 통신 서비스
├── helpers/                           # 유틸리티 헬퍼
│   ├── api_exception.dart            # API 예외 처리
│   ├── cache_helper.dart             # 로컬 캐시 관리
│   ├── network_helper.dart           # 네트워크 상태 관리
│   ├── notification_helper.dart      # 알림 헬퍼
│   └── permission_helper.dart        # 권한 관리
├── screens/                           # 화면 UI
│   ├── home_screen.dart              # 홈 화면 (센서 데이터 표시)
│   ├── history_screen.dart           # 과거 데이터 차트 화면
│   ├── notification_screen.dart      # 알림 목록 화면
│   └── settings_screen.dart          # 설정 화면
└── widgets/                           # 재사용 가능한 위젯
    ├── sensor_card.dart              # 센서 데이터 카드
    ├── plant_registration_form.dart  # 식물 등록 폼
    ├── plant_settings_dialog.dart    # 식물 설정 다이얼로그
    ├── notification_item_tile.dart   # 알림 항목 타일
    ├── settings_section.dart         # 설정 섹션
    ├── info_row.dart                 # 정보 행 위젯
    ├── chart_legend.dart             # 차트 범례
    └── period_selector.dart          # 기간 선택기
```

## 🌐 API 연동

### Base URL
```
https://api.smartfarm.com/v1
```

### 주요 엔드포인트

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/plants` | 식물 등록 |
| GET | `/plants/{id}` | 식물 정보 조회 |
| PUT | `/plants/{id}` | 식물 정보 수정 |
| DELETE | `/plants/{id}` | 식물 삭제 |
| GET | `/plants/{id}/sensors/current` | 현재 센서 데이터 |
| GET | `/plants/{id}/sensors/history` | 과거 센서 데이터 |
| GET | `/plants/{id}/notifications` | 알림 목록 |
| POST | `/plants/identify` | AI 식물 인식 |
| GET | `/plant-profiles` | 식물 프로파일 목록 |
| GET | `/settings` | 사용자 설정 조회 |
| PUT | `/settings` | 사용자 설정 업데이트 |

## 📱 화면 구성

### 1. 홈 화면 (Home Screen)
- 등록된 식물 정보 표시
- 실시간 센서 데이터 (온도, 습도, 토양수분, 조도)
- 식물 상태 종합 평가
- 식물 등록 기능 (수동/AI 인식)

### 2. 데이터 화면 (History Screen)
- 센서 데이터 시계열 차트
- 기간별 데이터 조회 (24시간, 7일, 30일, 90일)
- 평균값 및 통계 정보
- 데이터 요약 카드

### 3. 알림 화면 (Notification Screen)
- 알림 목록 (경고, 정보, 오류)
- 읽음/읽지 않음 상태 관리
- 알림 통계
- 일괄 읽음 처리

### 4. 설정 화면 (Settings Screen)
- 연결 상태 확인
- 등록된 식물 관리
- 최적 환경 범위 설정
- 알림 설정 (푸시 알림 on/off)
- 앱 설정 (언어, 테마)
- 데이터 관리 (캐시 초기화 등)

## 🔧 핵심 기능 구현

### State Management (Provider 패턴)
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => PlantProvider()),
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ChangeNotifierProvider(create: (_) => NavigationProvider()),
  ],
  child: MyApp(),
)
```

### 네트워크 상태 감지
- 실시간 연결 상태 모니터링
- 오프라인 모드 지원
- 자동 재연결 및 데이터 동기화

### 캐시 시스템
- 로컬 데이터 저장 (SharedPreferences)
- 오프라인 사용을 위한 데이터 보존
- 캐시 만료 및 갱신 관리

### AI 식물 인식
- 이미지 업로드를 통한 식물 종 식별
- 인식 정확도 검증
- 자동 최적 환경 설정 제안

## 🚀 시작하기

### 필수 요구사항
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- Android 5.0+ / iOS 12.0+

### 설치 및 실행

1. **저장소 클론**
```bash
git clone https://github.com/your-username/smartfarm.git
cd smartfarm
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **앱 실행**
```bash
flutter run
```

### 주요 의존성 패키지

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5
  http: ^1.1.0
  shared_preferences: ^2.2.0
  fl_chart: ^0.63.0
  image_picker: ^1.0.4
  permission_handler: ^11.0.1
  connectivity_plus: ^4.0.2
```

## 🔒 권한 설정

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### iOS (ios/Runner/Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>식물 사진을 촬영하여 AI 인식 기능을 사용합니다.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>갤러리에서 식물 사진을 선택하여 AI 인식 기능을 사용합니다.</string>
```

## 🧪 테스트

### 단위 테스트 실행
```bash
flutter test
```

### 통합 테스트 실행
```bash
flutter drive --target=test_driver/app.dart
```

## 📦 빌드 및 배포

### Android APK 빌드
```bash
flutter build apk --release
```

### iOS IPA 빌드
```bash
flutter build ios --release
```

## 🤝 기여 방법

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 확인해주세요.

## 📞 문의

- **이메일**: smartfarm.support@example.com
- **이슈 신고**: [GitHub Issues](https://github.com/your-username/smartfarm/issues)
- **문서**: [Wiki](https://github.com/your-username/smartfarm/wiki)

## 🔮 향후 계획

- [ ] 복수 식물 동시 관리
- [ ] 소셜 기능 (식물 성장 공유)
- [ ] 머신러닝 기반 식물 건강 예측
- [ ] IoT 디바이스 직접 연동
- [ ] 웹 대시보드 개발
- [ ] 다국어 지원 확장

---

**⭐ 이 프로젝트가 도움이 되셨다면 별표를 눌러주세요!**