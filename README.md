프로젝트 구조
==============

    lib/
    ├── main.dart                      # 앱 진입점 + Provider 설정
    ├── models/                        # 데이터 모델
    │   ├── plant.dart                 # Plant 모델
    │   └── app_models.dart            # 기타 모든 모델들 (export)
    ├── providers/                     # 상태 관리
    │   ├── plant_provider.dart        # 식물 관련 상태
    │   └── settings_provider.dart     # 설정 상태
    ├── services/                      # 외부 서비스
    │   └── api_service.dart           # API 통신
    ├── screens/                       # 화면 위젯
    │   ├── home_screen.dart           # 홈 화면
    │   ├── history_screen.dart        # 데이터 기록 화면
    │   ├── notification_screen.dart   # 알림 화면
    │   └── settings_screen.dart       # 설정 화면
    ├── widgets/                       # 재사용 가능한 위젯
    │   ├── sensor_card.dart           # 센서 데이터 카드
    │   ├── plant_registration_form.dart # 식물 등록 폼
    │   ├── period_selector.dart       # 기간 선택 위젯
    │   ├── chart_legend.dart          # 차트 범례
    │   ├── notification_item_tile.dart # 알림 아이템
    │   ├── plant_settings_dialog.dart # 식물 설정 다이얼로그
    │   ├── settings_section.dart      # 설정 섹션
    │   └── info_row.dart              # 정보 행 위젯
    └── helpers/                       # 유틸리티
        ├── api_exception.dart         # API 예외 처리
        ├── network_helper.dart        # 네트워크 상태 관리
        ├── database_helper.dart       # 로컬 데이터베이스
        ├── cache_helper.dart          # 캐시 관리
        ├── sync_helper.dart           # 데이터 동기화
        ├── notification_helper.dart   # 알림 헬퍼
        └── permission_helper.dart     # 권한 관리
