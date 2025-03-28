import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/plant.dart';
import '../models/plant_species.dart';
import '../models/sensor_data.dart';
import '../services/api_service.dart';
import '../services/mock_api_service.dart'; // 테스트용 서비스 추가
import '../services/notification_service.dart';

class PlantProvider with ChangeNotifier {
  // 테스트 모드 여부
  final bool testMode;

  // 서비스 인스턴스 (실제 또는 테스트용)
  late final dynamic _apiService;
  final NotificationService _notificationService = NotificationService();

  // 상태 변수
  List<Plant> _plants = [];
  List<PlantSpecies> _species = [];
  bool _isLoading = false;
  String? _error;

  // 정기적인 데이터 업데이트를 위한 타이머
  Timer? _refreshTimer;

  // 게터
  List<Plant> get plants => _plants;
  List<PlantSpecies> get species => _species;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 생성자
  PlantProvider({this.testMode = false}) {
    // 테스트 모드에 따라 적절한 서비스 사용
    _apiService = testMode ? MockApiService() : ApiService();
    _initData();
  }

  // 초기 데이터 로드
  Future<void> _initData() async {
    await _loadSpecies();
    await _loadPlants();

    // 앱 활성화 상태에서 주기적으로 데이터 갱신
    // 테스트 모드에서는 더 짧은 간격으로 갱신 (실시간 변화 시뮬레이션)
    _refreshTimer = Timer.periodic(
        Duration(minutes: testMode ? 1 : 5),
            (timer) {
          refreshPlantsData();
        }
    );
  }

  // 식물 종 정보 로드
  Future<void> _loadSpecies() async {
    _setLoading(true);

    try {
      _species = await _apiService.getSpecies();
      _setError(null);
    } catch (e) {
      _setError('식물 종 정보를 불러오는데 실패했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 식물 목록 로드
  Future<void> _loadPlants() async {
    _setLoading(true);

    try {
      _plants = await _apiService.getPlants();
      _setError(null);
    } catch (e) {
      _setError('식물 목록을 불러오는데 실패했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 새 식물 추가
  Future<Plant?> addPlant(String name, String speciesId) async {
    _setLoading(true);

    try {
      // 새 식물 객체 생성
      final newPlant = Plant(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // 임시 ID
        name: name,
        speciesId: speciesId,
      );

      // API를 통해 식물 등록
      final addedPlant = await _apiService.addPlant(newPlant);

      // 로컬 목록에 추가
      _plants.add(addedPlant);
      notifyListeners();

      _setError(null);
      return addedPlant;
    } catch (e) {
      _setError('식물 추가에 실패했습니다: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // 특정 식물의 데이터 새로고침
  Future<void> refreshPlantData(String plantId) async {
    try {
      // 현재 식물 정보 찾기
      final plantIndex = _plants.indexWhere((p) => p.id == plantId);
      if (plantIndex < 0) return;

      // 센서 데이터 가져오기
      final sensorData = await _apiService.getPlantData(plantId);

      if (sensorData.isNotEmpty) {
        // 최신 데이터
        final latestData = sensorData.last;

        // 식물 정보 업데이트
        final updatedPlant = _plants[plantIndex].copyWith(
          sensorHistory: sensorData,
          latestData: latestData,
        );

        // 목록 업데이트
        _plants[plantIndex] = updatedPlant;

        // 환경 확인 및 알림
        _checkPlantEnvironment(updatedPlant);

        notifyListeners();
      }
    } catch (e) {
      print('식물 데이터 갱신 실패: $e');
    }
  }

  // 모든 식물의 데이터 새로고침
  Future<void> refreshPlantsData() async {
    for (final plant in _plants) {
      await refreshPlantData(plant.id);
    }
  }

  // 특정 식물 종 정보 가져오기
  PlantSpecies? getSpeciesById(String speciesId) {
    try {
      return _species.firstWhere((s) => s.id == speciesId);
    } catch (e) {
      return null;
    }
  }

  // 특정 식물의 환경 적합성 확인 및 알림
  void _checkPlantEnvironment(Plant plant) {
    final species = getSpeciesById(plant.speciesId);
    if (species == null || plant.latestData == null) return;

    // 알림 메시지 생성
    final alertMessage = plant.generateAlertMessage(species);

    // 알림이 필요한 경우 표시
    if (alertMessage != null && alertMessage.isNotEmpty) {
      _notificationService.showPlantNotification(
        title: '식물 케어 알림',
        message: alertMessage,
        payload: plant.id,
      );
    }
  }

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 오류 상태 설정
  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  @override
  void dispose() {
    // 타이머 해제
    _refreshTimer?.cancel();
    super.dispose();
  }
}