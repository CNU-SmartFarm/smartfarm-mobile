import 'package:flutter/material.dart';
import 'dart:io';

import '../models/plant.dart';
import '../models/sensor_data.dart';
import '../models/notification_item.dart';
import '../models/historical_data_point.dart';
import '../models/plant_profile.dart';
import '../models/ai_identification_result.dart';
import '../services/api_service.dart';
import '../helpers/network_helper.dart';
import '../helpers/cache_helper.dart';

class PlantProvider extends ChangeNotifier {
  Plant? _plant;
  SensorData? _sensorData;
  List<NotificationItem> _notifications = [];
  List<HistoricalDataPoint> _historicalData = [];
  List<PlantProfile> _plantProfiles = [];
  String _selectedPeriod = '24h';
  bool _isLoading = false;
  String? _error;

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

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  void clearError() {
    _setError(null);
  }

  // 초기화
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _setError(null);

      await loadPlantProfiles();

      final lastPlantId = CacheHelper.getString(CacheHelper.CURRENT_PLANT_ID);
      if (lastPlantId != null && lastPlantId.isNotEmpty) {
        await loadPlant(lastPlantId);
      }
    } catch (e) {
      _setError('초기화 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 식물 프로파일 로드
  Future<void> loadPlantProfiles() async {
    try {
      if (NetworkHelper.isOnline) {
        _plantProfiles = await ApiService.getPlantProfiles();

        // 캐시에 저장
        await CacheHelper.setJson(CacheHelper.PLANT_PROFILES_CACHE, {
          'data': _plantProfiles.map((profile) => profile.toJson()).toList(),
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      } else {
        // 캐시에서 로드
        final cachedProfiles = CacheHelper.getJson(CacheHelper.PLANT_PROFILES_CACHE);
        if (cachedProfiles != null && cachedProfiles['data'] != null) {
          List<dynamic> profilesData = cachedProfiles['data'];
          _plantProfiles = profilesData.map((item) => PlantProfile.fromJson(item)).toList();
        } else {
          _plantProfiles = _getDefaultPlantProfiles();
        }
      }
      notifyListeners();
    } catch (e) {
      _setError('식물 프로파일을 불러오는데 실패했습니다: $e');
      _plantProfiles = _getDefaultPlantProfiles();
      notifyListeners();
    }
  }

  // 식물 로드
  Future<void> loadPlant(String plantId) async {
    try {
      _setLoading(true);
      _setError(null);

      _plant = await ApiService.getPlant(plantId);
      if (_plant != null) {
        await CacheHelper.setString(CacheHelper.CURRENT_PLANT_ID, _plant!.id);
        await loadPlantData();
      } else {
        _setError('식물 정보를 찾을 수 없습니다.');
      }

      notifyListeners();
    } catch (e) {
      _setError('식물 정보 로드 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 식물 등록
  Future<bool> registerPlant(Plant plant) async {
    _setLoading(true);
    _setError(null);

    try {
      Plant? registeredPlant = await ApiService.registerPlant(plant);

      if (registeredPlant != null) {
        _plant = registeredPlant;
        await CacheHelper.setString(CacheHelper.CURRENT_PLANT_ID, registeredPlant.id);
        await loadPlantData();
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

  // AI 식물 등록
  Future<bool> registerPlantWithAI(File imageFile) async {
    _setLoading(true);
    _setError(null);

    try {
      if (!NetworkHelper.isOnline) {
        _setError('AI 인식은 인터넷 연결이 필요합니다.');
        return false;
      }

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
        id: '',
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

      return await registerPlant(aiRecognizedPlant);
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
      Plant? result = await ApiService.updatePlant(_plant!.id, updatedPlant);

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
      bool success = await ApiService.deletePlant(_plant!.id);

      if (success) {
        _plant = null;
        _sensorData = null;
        _notifications.clear();
        _historicalData.clear();
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

      final results = await Future.wait([
        ApiService.getCurrentSensorData(_plant!.id),
        ApiService.getNotifications(_plant!.id),
        ApiService.getHistoricalData(_plant!.id, _selectedPeriod),
      ]);

      _sensorData = results[0] as SensorData?;
      _notifications = results[1] as List<NotificationItem>;
      _historicalData = results[2] as List<HistoricalDataPoint>;

      notifyListeners();
    } catch (e) {
      _setError('식물 데이터 로드 실패: $e');
    }
  }

  // 과거 데이터 로드
  Future<void> loadHistoricalData() async {
    if (_plant == null) return;

    try {
      _setError(null);
      _historicalData = await ApiService.getHistoricalData(_plant!.id, _selectedPeriod);
      notifyListeners();
    } catch (e) {
      _setError('과거 데이터 로드 실패: $e');
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
      bool success = await ApiService.markNotificationAsRead(notificationId);

      if (success && index < _notifications.length) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
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

  // 프로파일 관련 메서드
  PlantProfile? getProfileBySpecies(String species) {
    try {
      return _plantProfiles.firstWhere((profile) => profile.species == species);
    } catch (e) {
      return null;
    }
  }

  List<PlantProfile> searchProfiles(String query) {
    if (query.isEmpty) return _plantProfiles;

    String lowerQuery = query.toLowerCase();
    return _plantProfiles.where((profile) {
      return profile.commonName.toLowerCase().contains(lowerQuery) ||
          profile.species.toLowerCase().contains(lowerQuery);
    }).toList();
  }

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

  bool isCacheExpired() {
    final lastUpdated = getCachedProfilesAge();
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated).inHours >= 24;
  }

  Future<void> refreshPlantProfiles() async {
    if (!NetworkHelper.isOnline) {
      _setError('네트워크 연결을 확인해주세요.');
      return;
    }

    _setLoading(true);
    try {
      _setError(null);
      await loadPlantProfiles();
    } catch (e) {
      _setError('식물 프로파일 새로고침 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 기본 식물 프로파일
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
    ];
  }
}