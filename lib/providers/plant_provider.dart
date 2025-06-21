import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import '../models/app_models.dart';
import '../services/api_service.dart';
import '../helpers/network_helper.dart';
import '../helpers/cache_helper.dart';
import '../helpers/database_helper.dart';

class PlantProvider extends ChangeNotifier {
  Plant? _plant;
  SensorData? _sensorData;
  List<NotificationItem> _notifications = [];
  List<HistoricalDataPoint> _historicalData = [];
  List<PlantProfile> _plantProfiles = [];
  String _selectedPeriod = '24h';
  bool _isLoading = false;
  String? _error;
  Timer? _sensorTimer;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Getters
  Plant? get plant => _plant;
  SensorData? get sensorData => _sensorData;
  List<NotificationItem> get notifications => _notifications;
  List<HistoricalDataPoint> get historicalData => _historicalData;
  List<PlantProfile> get plantProfiles => _plantProfiles;
  String get selectedPeriod => _selectedPeriod;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPlant => _plant != null;

  // 로딩 상태 관리
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // 에러 상태 관리
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  // 에러 클리어
  void clearError() {
    _setError(null);
  }

  // 앱 초기화 시 데이터 로드
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _setError(null);

      // 식물 프로파일 로드
      await loadPlantProfiles();

      // 마지막 등록된 식물 ID 확인
      final lastPlantId = CacheHelper.getString(CacheHelper.CURRENT_PLANT_ID);
      if (lastPlantId != null && lastPlantId.isNotEmpty) {
        await loadPlant(lastPlantId);
      } else {
        // 서버에서 사용자의 식물 목록 확인
        await _loadUserPlants();
      }

    } catch (e) {
      _setError('초기화 중 오류가 발생했습니다: $e');
      print('Initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 사용자의 식물 목록 로드
  Future<void> _loadUserPlants() async {
    try {
      if (!NetworkHelper.isOnline) return;

      List<Plant> plants = await ApiService.getAllPlants();
      if (plants.isNotEmpty) {
        // 첫 번째 식물을 현재 식물로 설정
        _plant = plants.first;
        await CacheHelper.setString(CacheHelper.CURRENT_PLANT_ID, _plant!.id);
        await loadPlantData();
        _startPeriodicUpdates();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user plants: $e');
    }
  }

  // 특정 식물 로드
  Future<void> loadPlant(String plantId) async {
    try {
      _setLoading(true);
      _setError(null);

      if (NetworkHelper.isOnline) {
        Plant? plant = await ApiService.getPlant(plantId);
        if (plant != null) {
          _plant = plant;
          await CacheHelper.setString(CacheHelper.CURRENT_PLANT_ID, plant.id);
          await loadPlantData();
          _startPeriodicUpdates();
        } else {
          _setError('식물 정보를 찾을 수 없습니다.');
        }
      } else {
        // 오프라인 모드에서는 로컬 DB에서 로드
        final plantData = await _dbHelper.getPlant(plantId);
        if (plantData != null) {
          _plant = Plant.fromJson(plantData);
          await _loadOfflineData();
        } else {
          _setError('오프라인에서 식물 정보를 찾을 수 없습니다.');
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('식물 정보 로드 실패: $e');
      print('Error loading plant: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 오프라인 데이터 로드
  Future<void> _loadOfflineData() async {
    if (_plant == null) return;

    try {
      // 최신 센서 데이터 로드
      final sensorDataMap = await _dbHelper.getLatestSensorData(_plant!.id);
      if (sensorDataMap != null) {
        _sensorData = SensorData.fromJson(sensorDataMap);
      }

      // 알림 로드
      final notificationMaps = await _dbHelper.getNotifications(_plant!.id);
      _notifications = notificationMaps.map((map) => NotificationItem.fromJson(map)).toList();

      // 과거 데이터 로드
      final historicalMaps = await _dbHelper.getHistoricalSensorData(_plant!.id, _selectedPeriod);
      _historicalData = historicalMaps.map((map) => HistoricalDataPoint.fromJson(map)).toList();

    } catch (e) {
      print('Error loading offline data: $e');
    }
  }

  // 식물 프로파일 로드 - API 우선, 실패 시 캐시 사용
  Future<void> loadPlantProfiles() async {
    try {
      _setError(null);

      // 먼저 캐시에서 로드 (빠른 UI 응답)
      final cachedProfiles = CacheHelper.getJson(CacheHelper.PLANT_PROFILES_CACHE);
      if (cachedProfiles != null && cachedProfiles['data'] != null) {
        List<dynamic> profilesData = cachedProfiles['data'];
        _plantProfiles = profilesData.map((item) => PlantProfile.fromJson(item)).toList();
        notifyListeners();
      }

      // 네트워크가 연결되어 있으면 API에서 최신 데이터 가져오기
      if (NetworkHelper.isOnline) {
        try {
          List<PlantProfile> apiProfiles = await ApiService.getPlantProfiles();

          if (apiProfiles.isNotEmpty) {
            _plantProfiles = apiProfiles;

            // 성공적으로 가져온 데이터를 캐시에 저장
            await CacheHelper.setJson(CacheHelper.PLANT_PROFILES_CACHE, {
              'data': apiProfiles.map((profile) => profile.toJson()).toList(),
              'lastUpdated': DateTime.now().toIso8601String(),
            });

            notifyListeners();
            print('식물 프로파일 API에서 성공적으로 로드: ${apiProfiles.length}개');
          } else if (_plantProfiles.isEmpty) {
            // API 응답이 비어있고 캐시도 없으면 기본 데이터 사용
            _plantProfiles = _getDefaultPlantProfiles();
            print('API 응답이 비어있어 기본 데이터 사용');
            notifyListeners();
          }
        } catch (apiError) {
          print('API 호출 실패: $apiError');

          // API 실패했지만 캐시된 데이터가 없으면 기본 데이터 사용
          if (_plantProfiles.isEmpty) {
            _plantProfiles = _getDefaultPlantProfiles();
            print('API 실패 및 캐시 없음, 기본 데이터 사용');
            notifyListeners();
          }
          // 캐시된 데이터가 있으면 그것을 계속 사용 (이미 위에서 로드됨)
        }
      } else {
        // 오프라인이고 캐시된 데이터가 없으면 기본 데이터 사용
        if (_plantProfiles.isEmpty) {
          _plantProfiles = _getDefaultPlantProfiles();
          print('오프라인 상태, 기본 데이터 사용');
          notifyListeners();
        }
      }

    } catch (e) {
      _setError('식물 프로파일을 불러오는데 실패했습니다: $e');
      print('Error loading plant profiles: $e');

      // 에러가 발생해도 기본 데이터는 제공
      if (_plantProfiles.isEmpty) {
        _plantProfiles = _getDefaultPlantProfiles();
        notifyListeners();
      }
    }
  }

  // 식물 프로파일 새로고침 (강제로 API에서 다시 가져오기)
  Future<void> refreshPlantProfiles() async {
    if (!NetworkHelper.isOnline) {
      _setError('네트워크 연결을 확인해주세요.');
      return;
    }

    _setLoading(true);
    try {
      _setError(null);

      List<PlantProfile> apiProfiles = await ApiService.getPlantProfiles();

      if (apiProfiles.isNotEmpty) {
        _plantProfiles = apiProfiles;

        // 캐시 업데이트
        await CacheHelper.setJson(CacheHelper.PLANT_PROFILES_CACHE, {
          'data': apiProfiles.map((profile) => profile.toJson()).toList(),
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        notifyListeners();
        print('식물 프로파일 새로고침 완료: ${apiProfiles.length}개');
      } else {
        _setError('서버에서 식물 프로파일을 가져올 수 없습니다.');
      }
    } catch (e) {
      _setError('식물 프로파일 새로고침 실패: $e');
      print('Error refreshing plant profiles: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 특정 종의 프로파일 찾기
  PlantProfile? getProfileBySpecies(String species) {
    try {
      return _plantProfiles.firstWhere((profile) => profile.species == species);
    } catch (e) {
      return null;
    }
  }

  // 일반명으로 프로파일 검색
  List<PlantProfile> searchProfiles(String query) {
    if (query.isEmpty) return _plantProfiles;

    String lowerQuery = query.toLowerCase();
    return _plantProfiles.where((profile) {
      return profile.commonName.toLowerCase().contains(lowerQuery) ||
          profile.species.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // 캐시된 프로파일이 얼마나 오래되었는지 확인
  DateTime? getCachedProfilesAge() {
    final cachedProfiles = CacheHelper.getJson(CacheHelper.PLANT_PROFILES_CACHE);
    if (cachedProfiles != null && cachedProfiles['lastUpdated'] != null) {
      try {
        return DateTime.parse(cachedProfiles['lastUpdated']);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // 캐시가 오래되었는지 확인 (24시간 기준)
  bool isCacheExpired() {
    final lastUpdated = getCachedProfilesAge();
    if (lastUpdated == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    return difference.inHours >= 24;
  }

  // 식물 등록
  Future<bool> registerPlant(Plant plant) async {
    _setLoading(true);
    _setError(null);

    try {
      Plant? registeredPlant;

      if (NetworkHelper.isOnline) {
        registeredPlant = await ApiService.registerPlant(plant);
        if (registeredPlant != null) {
          // 로컬 DB에도 저장
          await _dbHelper.insertPlant(registeredPlant.toJson());
        }
      } else {
        // 오프라인 모드에서는 로컬에만 저장
        plant = plant.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
        await _dbHelper.insertPlant(plant.toJson());
        registeredPlant = plant;
      }

      if (registeredPlant != null) {
        _plant = registeredPlant;
        await CacheHelper.setString(CacheHelper.CURRENT_PLANT_ID, registeredPlant.id);
        await loadPlantData();
        _startPeriodicUpdates();
        notifyListeners();
        return true;
      } else {
        _setError('식물 등록에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError('식물 등록 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // AI 식물 등록 (실제 PlantNet API 사용)
  Future<bool> registerPlantWithAI(File imageFile) async {
    _setLoading(true);
    _setError(null);

    try {
      if (!NetworkHelper.isOnline) {
        _setError('AI 인식은 인터넷 연결이 필요합니다.');
        return false;
      }

      // PlantNet API 호출
      AIIdentificationResult? result = await ApiService.identifyPlant(imageFile);

      if (result == null) {
        _setError('식물을 인식할 수 없습니다. 다시 시도해주세요.');
        return false;
      }

      if (result.confidence < 0.3) {
        _setError('식물 인식 정확도가 낮습니다 (${(result.confidence * 100).toStringAsFixed(1)}%). 더 선명한 사진으로 다시 시도해주세요.');
        return false;
      }

      Plant aiRecognizedPlant = Plant(
        id: '', // API에서 생성됨
        name: result.suggestedName,
        species: result.species,
        registeredDate: DateTime.now().toString().split(' ')[0],
        optimalTempMin: result.optimalSettings['optimalTempMin']!,
        optimalTempMax: result.optimalSettings['optimalTempMax']!,
        optimalHumidityMin: result.optimalSettings['optimalHumidityMin']!,
        optimalHumidityMax: result.optimalSettings['optimalHumidityMax']!,
        optimalSoilMoistureMin: result.optimalSettings['optimalSoilMoistureMin']!,
        optimalSoilMoistureMax: result.optimalSettings['optimalSoilMoistureMax']!,
        optimalLightMin: result.optimalSettings['optimalLightMin']!,
        optimalLightMax: result.optimalSettings['optimalLightMax']!,
      );

      bool success = await registerPlant(aiRecognizedPlant);

      if (success) {
        print('AI 인식 성공: ${result.species}, 정확도: ${(result.confidence * 100).toStringAsFixed(1)}%');
      }

      return success;
    } catch (e) {
      _setError('AI 인식에 실패했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 식물 정보 업데이트
  Future<bool> updatePlant(Plant updatedPlant) async {
    if (_plant == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      Plant? result;

      if (NetworkHelper.isOnline) {
        result = await ApiService.updatePlant(_plant!.id, updatedPlant);
        if (result != null) {
          // 로컬 DB도 업데이트
          await _dbHelper.updatePlant(result.id, result.toJson());
        }
      } else {
        // 오프라인 모드에서는 로컬만 업데이트
        await _dbHelper.updatePlant(_plant!.id, updatedPlant.toJson());
        result = updatedPlant;
      }

      if (result != null) {
        _plant = result;
        notifyListeners();
        return true;
      } else {
        _setError('식물 정보 업데이트에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError('식물 정보 업데이트 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 식물 삭제
  Future<bool> deletePlant() async {
    if (_plant == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      bool success = false;

      if (NetworkHelper.isOnline) {
        success = await ApiService.deletePlant(_plant!.id);
      } else {
        success = true; // 오프라인에서는 로컬에서만 삭제
      }

      if (success) {
        // 로컬 DB에서도 삭제
        await _dbHelper.deletePlant(_plant!.id);

        _plant = null;
        _sensorData = null;
        _notifications.clear();
        _historicalData.clear();
        _stopPeriodicUpdates();
        await CacheHelper.remove(CacheHelper.CURRENT_PLANT_ID);
        notifyListeners();
        return true;
      } else {
        _setError('식물 삭제에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError('식물 삭제 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 식물 데이터 로드
  Future<void> loadPlantData() async {
    if (_plant == null) return;

    try {
      _setError(null);

      if (NetworkHelper.isOnline) {
        // 온라인 모드: API에서 데이터 로드
        final results = await Future.wait([
          ApiService.getCurrentSensorData(_plant!.id),
          ApiService.getNotifications(_plant!.id),
          ApiService.getHistoricalData(_plant!.id, _selectedPeriod),
        ]);

        _sensorData = results[0] as SensorData?;
        _notifications = results[1] as List<NotificationItem>;
        _historicalData = results[2] as List<HistoricalDataPoint>;

        // 로컬 DB에도 저장
        if (_sensorData != null) {
          await _dbHelper.insertSensorData(_sensorData!.toJson());
        }

        for (final notification in _notifications) {
          await _dbHelper.insertNotification(notification.toJson());
        }
      } else {
        // 오프라인 모드: 로컬 DB에서 데이터 로드
        await _loadOfflineData();
      }

      notifyListeners();
    } catch (e) {
      _setError('식물 데이터 로드 실패: $e');
      print('Error loading plant data: $e');
    }
  }

  // 과거 데이터 로드
  Future<void> loadHistoricalData() async {
    if (_plant == null) return;

    try {
      _setError(null);

      if (NetworkHelper.isOnline) {
        _historicalData = await ApiService.getHistoricalData(_plant!.id, _selectedPeriod);
      } else {
        final historicalMaps = await _dbHelper.getHistoricalSensorData(_plant!.id, _selectedPeriod);
        _historicalData = historicalMaps.map((map) => HistoricalDataPoint.fromJson(map)).toList();
      }

      notifyListeners();
    } catch (e) {
      _setError('과거 데이터 로드 실패: $e');
      print('Error loading historical data: $e');
    }
  }

  // 기간 선택 변경
  void setSelectedPeriod(String period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      notifyListeners();
      loadHistoricalData();
    }
  }

  // 알림 읽음 처리
  Future<void> markNotificationAsRead(int notificationId, int index) async {
    try {
      bool success = false;

      if (NetworkHelper.isOnline) {
        success = await ApiService.markNotificationAsRead(notificationId);
      } else {
        success = true; // 오프라인에서는 로컬에서만 처리
      }

      if (success && index < _notifications.length) {
        await _dbHelper.markNotificationAsRead(notificationId);
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // 주기적 업데이트 시작
  void _startPeriodicUpdates() {
    _stopPeriodicUpdates();
    _sensorTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_plant != null && NetworkHelper.isOnline) {
        loadPlantData();
      }
    });
  }

  // 주기적 업데이트 중지
  void _stopPeriodicUpdates() {
    _sensorTimer?.cancel();
    _sensorTimer = null;
  }

  // 센서 데이터 상태 체크
  bool isValueInRange(double value, double min, double max) {
    return value >= min && value <= max;
  }

  // 전체 상태 계산
  String getOverallStatus() {
    if (_sensorData == null || _plant == null) return '알 수 없음';

    bool tempOk = isValueInRange(_sensorData!.temperature, _plant!.optimalTempMin, _plant!.optimalTempMax);
    bool humidityOk = isValueInRange(_sensorData!.humidity, _plant!.optimalHumidityMin, _plant!.optimalHumidityMax);
    bool soilOk = isValueInRange(_sensorData!.soilMoisture, _plant!.optimalSoilMoistureMin, _plant!.optimalSoilMoistureMax);
    bool lightOk = isValueInRange(_sensorData!.light, _plant!.optimalLightMin, _plant!.optimalLightMax);

    int okCount = [tempOk, humidityOk, soilOk, lightOk].where((x) => x).length;

    if (okCount == 4) return '최적';
    if (okCount >= 2) return '양호';
    return '주의 필요';
  }

  // 상태 색상 계산
  Color getOverallStatusColor() {
    String status = getOverallStatus();
    switch (status) {
      case '최적':
        return Color(0xFF2E7D32);
      case '양호':
        return Color(0xFF66BB6A);
      case '주의 필요':
        return Color(0xFFE53E3E);
      default:
        return Color(0xFF999999);
    }
  }

  // 읽지 않은 알림 수
  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  // 연결 상태 확인
  Future<bool> checkConnection() async {
    try {
      return await ApiService.testConnection();
    } catch (e) {
      return false;
    }
  }

  // 데이터 동기화 (오프라인에서 온라인으로 전환시 사용)
  Future<void> syncData() async {
    if (!NetworkHelper.isOnline || _plant == null) return;

    try {
      // 서버의 최신 데이터로 동기화
      await loadPlantData();
      print('Data synchronized successfully');
    } catch (e) {
      print('Error syncing data: $e');
    }
  }

  // 임시 식물 프로파일 데이터 (API 실패 시 fallback)
  List<PlantProfile> _getDefaultPlantProfiles() {
    return [
      PlantProfile(
        species: 'Monstera deliciosa',
        commonName: '몬스테라',
        optimalTempMin: 18,
        optimalTempMax: 25,
        optimalHumidityMin: 50,
        optimalHumidityMax: 70,
        optimalSoilMoistureMin: 40,
        optimalSoilMoistureMax: 60,
        optimalLightMin: 40,
        optimalLightMax: 70,
        description: '실내에서 기르기 쉬운 대형 관엽식물',
      ),
      PlantProfile(
        species: 'Pothos aureus',
        commonName: '포토스',
        optimalTempMin: 16,
        optimalTempMax: 24,
        optimalHumidityMin: 40,
        optimalHumidityMax: 60,
        optimalSoilMoistureMin: 30,
        optimalSoilMoistureMax: 50,
        optimalLightMin: 30,
        optimalLightMax: 60,
        description: '초보자도 키우기 쉬운 덩굴성 식물',
      ),
      PlantProfile(
        species: 'Sansevieria trifasciata',
        commonName: '산세베리아',
        optimalTempMin: 15,
        optimalTempMax: 28,
        optimalHumidityMin: 30,
        optimalHumidityMax: 50,
        optimalSoilMoistureMin: 20,
        optimalSoilMoistureMax: 40,
        optimalLightMin: 20,
        optimalLightMax: 80,
        description: '공기정화 효과가 뛰어난 다육식물',
      ),
      PlantProfile(
        species: 'Ficus elastica',
        commonName: '고무나무',
        optimalTempMin: 18,
        optimalTempMax: 26,
        optimalHumidityMin: 45,
        optimalHumidityMax: 65,
        optimalSoilMoistureMin: 35,
        optimalSoilMoistureMax: 55,
        optimalLightMin: 50,
        optimalLightMax: 80,
        description: '광택이 나는 큰 잎이 특징인 관엽식물',
      ),
      PlantProfile(
        species: 'Dracaena fragrans',
        commonName: '드라세나',
        optimalTempMin: 16,
        optimalTempMax: 24,
        optimalHumidityMin: 40,
        optimalHumidityMax: 60,
        optimalSoilMoistureMin: 30,
        optimalSoilMoistureMax: 50,
        optimalLightMin: 30,
        optimalLightMax: 70,
        description: '줄무늬 잎이 아름다운 실내식물',
      ),
      PlantProfile(
        species: 'Spathiphyllum wallisii',
        commonName: '스파티필름',
        optimalTempMin: 18,
        optimalTempMax: 25,
        optimalHumidityMin: 50,
        optimalHumidityMax: 70,
        optimalSoilMoistureMin: 50,
        optimalSoilMoistureMax: 70,
        optimalLightMin: 20,
        optimalLightMax: 50,
        description: '하얀 꽃이 피는 공기정화 식물',
      ),
      PlantProfile(
        species: 'Chlorophytum comosum',
        commonName: '스파이더 플랜트',
        optimalTempMin: 15,
        optimalTempMax: 24,
        optimalHumidityMin: 40,
        optimalHumidityMax: 60,
        optimalSoilMoistureMin: 35,
        optimalSoilMoistureMax: 55,
        optimalLightMin: 40,
        optimalLightMax: 80,
        description: '줄무늬 잎과 작은 새싹이 매력적인 식물',
      ),
      PlantProfile(
        species: 'Philodendron hederaceum',
        commonName: '필로덴드론',
        optimalTempMin: 18,
        optimalTempMax: 27,
        optimalHumidityMin: 50,
        optimalHumidityMax: 70,
        optimalSoilMoistureMin: 40,
        optimalSoilMoistureMax: 60,
        optimalLightMin: 30,
        optimalLightMax: 60,
        description: '하트 모양 잎이 아름다운 덩굴식물',
      ),
      PlantProfile(
        species: 'Aloe vera',
        commonName: '알로에',
        optimalTempMin: 16,
        optimalTempMax: 30,
        optimalHumidityMin: 20,
        optimalHumidityMax: 40,
        optimalSoilMoistureMin: 15,
        optimalSoilMoistureMax: 35,
        optimalLightMin: 60,
        optimalLightMax: 90,
        description: '약용으로도 사용되는 다육식물',
      ),
      PlantProfile(
        species: 'Zamioculcas zamiifolia',
        commonName: 'ZZ 플랜트',
        optimalTempMin: 15,
        optimalTempMax: 26,
        optimalHumidityMin: 30,
        optimalHumidityMax: 50,
        optimalSoilMoistureMin: 20,
        optimalSoilMoistureMax: 40,
        optimalLightMin: 20,
        optimalLightMax: 70,
        description: '물을 적게 줘도 되는 초보자용 식물',
      ),
    ];
  }

  @override
  void dispose() {
    _stopPeriodicUpdates();
    super.dispose();
  }
}