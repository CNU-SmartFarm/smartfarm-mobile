import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../models/app_models.dart';
import '../helpers/api_exception.dart';

class ApiService {
  static const String baseUrl = 'http://43.201.68.168:8080/api';
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  // 응답 처리 헬퍼 메서드
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw ApiException('Invalid JSON response', statusCode: response.statusCode);
      }
    } else {
      throw ApiException(
        'API request failed: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  // 식물 등록
  static Future<Plant?> registerPlant(Plant plant) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/plants'),
        headers: headers,
        body: jsonEncode({
          'name': plant.name,
          'species': plant.species,
          'optimalTempMin': plant.optimalTempMin,
          'optimalTempMax': plant.optimalTempMax,
          'optimalHumidityMin': plant.optimalHumidityMin,
          'optimalHumidityMax': plant.optimalHumidityMax,
          'optimalSoilMoistureMin': plant.optimalSoilMoistureMin,
          'optimalSoilMoistureMax': plant.optimalSoilMoistureMax,
          'optimalLightMin': plant.optimalLightMin,
          'optimalLightMax': plant.optimalLightMax,
        }),
      );

      if (response.statusCode == 201) {
        final data = _handleResponse(response);
        return Plant.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      print('Error registering plant: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to register plant: $e');
    }
  }

  // 식물 정보 조회
  static Future<Plant?> getPlant(String plantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plants/$plantId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return Plant.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      print('Error getting plant: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get plant: $e');
    }
  }

  // 식물 정보 수정
  static Future<Plant?> updatePlant(String plantId, Plant plant) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/plants/$plantId'),
        headers: headers,
        body: jsonEncode({
          'name': plant.name,
          'optimalTempMin': plant.optimalTempMin,
          'optimalTempMax': plant.optimalTempMax,
          'optimalHumidityMin': plant.optimalHumidityMin,
          'optimalHumidityMax': plant.optimalHumidityMax,
          'optimalSoilMoistureMin': plant.optimalSoilMoistureMin,
          'optimalSoilMoistureMax': plant.optimalSoilMoistureMax,
          'optimalLightMin': plant.optimalLightMin,
          'optimalLightMax': plant.optimalLightMax,
        }),
      );

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return Plant.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      print('Error updating plant: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update plant: $e');
    }
  }

  // 식물 삭제
  static Future<bool> deletePlant(String plantId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/plants/$plantId'),
        headers: headers,
      );

      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting plant: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete plant: $e');
    }
  }

  // 현재 센서 데이터 조회
  static Future<SensorData?> getCurrentSensorData(String plantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plants/$plantId/sensors/current'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return SensorData.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      print('Error getting sensor data: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get sensor data: $e');
    }
  }

  // 과거 센서 데이터 조회
  static Future<List<HistoricalDataPoint>> getHistoricalData(
      String plantId, String period) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plants/$plantId/sensors/history?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return (data['data'] as List)
            .map((item) => HistoricalDataPoint.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting historical data: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get historical data: $e');
    }
  }

  // 알림 목록 조회
  static Future<List<NotificationItem>> getNotifications(String plantId,
      {int limit = 10, int offset = 0, bool unreadOnly = false}) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        'unreadOnly': unreadOnly.toString(),
      };
      final uri = Uri.parse('$baseUrl/plants/$plantId/notifications')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return (data['data'] as List)
            .map((item) => NotificationItem.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting notifications: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get notifications: $e');
    }
  }

  // 알림 읽음 처리
  static Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to mark notification as read: $e');
    }
  }

  // 사용자 설정 조회
  static Future<Settings?> getSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return Settings.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      print('Error getting settings: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get settings: $e');
    }
  }

  // 사용자 설정 업데이트
  static Future<Settings?> updateSettings(Settings settings) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/settings'),
        headers: headers,
        body: jsonEncode({
          'pushNotificationEnabled': settings.pushNotificationEnabled,
          'language': settings.language,
          'theme': settings.theme,
        }),
      );

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return Settings.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      print('Error updating settings: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update settings: $e');
    }
  }

  // 식물 프로파일 목록 조회
  static Future<List<PlantProfile>> getPlantProfiles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plant-profiles'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return (data['data'] as List)
            .map((item) => PlantProfile.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting plant profiles: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get plant profiles: $e');
    }
  }

  // AI 식물 인식 (PlantNet API 사용)
  static Future<AIIdentificationResult?> identifyPlant(File imageFile) async {
    try {
      const String plantNetApiKey = '2b100lI28FM1Ei8FdhK8ddP5Y';
      const String plantNetUrl = 'https://my-api.plantnet.org/v2/identify/all';

      var uri = Uri.parse(plantNetUrl).replace(queryParameters: {
        'include-related-images': 'false',
        'no-reject': 'false',
        'nb-results': '5',
        'lang': 'en',
        'api-key': plantNetApiKey,
      });

      var request = http.MultipartRequest('POST', uri);

      // PlantNet API는 'images' 필드명을 사용
      request.files.add(
        await http.MultipartFile.fromPath(
          'images',
          imageFile.path,
          filename: 'plant_image.jpg',
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);

        // PlantNet API 응답을 우리 모델에 맞게 변환
        return _parsePlantNetResponse(data);
      } else {
        print('PlantNet API Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error identifying plant: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to identify plant: $e');
    }
  }

  // PlantNet API 응답을 AIIdentificationResult로 변환
  static AIIdentificationResult? _parsePlantNetResponse(Map<String, dynamic> data) {
    try {
      if (data['results'] == null || (data['results'] as List).isEmpty) {
        return null;
      }

      final bestResult = data['results'][0];
      final species = bestResult['species'];
      final score = (bestResult['score'] ?? 0.0).toDouble();

      String scientificName = species['scientificNameWithoutAuthor'] ?? '';
      String commonName = '';

      // 일반명 추출 (첫 번째 영어명 사용)
      if (species['commonNames'] != null && (species['commonNames'] as List).isNotEmpty) {
        commonName = species['commonNames'][0] ?? '';
      }

      // 한국어 일반명 매핑 (주요 식물들)
      Map<String, String> koreanNames = {
        'Monstera deliciosa': '몬스테라',
        'Pothos aureus': '포토스',
        'Sansevieria trifasciata': '산세베리아',
        'Ficus elastica': '고무나무',
        'Dracaena fragrans': '드라세나',
        'Spathiphyllum wallisii': '스파티필름',
        'Chlorophytum comosum': '스파이더 플랜트',
        'Philodendron hederaceum': '필로덴드론',
        'Aloe vera': '알로에',
        'Zamioculcas zamiifolia': 'ZZ 플랜트',
        'Epipremnum aureum': '골든 포토스',
        'Ficus benjamina': '벤자민 고무나무',
        'Rhaphidophora tetrasperma': '미니 몬스테라',
        'Monstera adansonii': '구멍몬스테라',
      };

      String suggestedName = koreanNames[scientificName] ?? commonName;
      if (suggestedName.isEmpty) {
        suggestedName = scientificName;
      }

      // 기본 최적 설정값 (식물에 따라 다르게 설정)
      Map<String, double> optimalSettings = _getOptimalSettingsForSpecies(scientificName);

      return AIIdentificationResult(
        species: scientificName,
        confidence: score,
        suggestedName: '내 $suggestedName',
        optimalSettings: optimalSettings,
      );
    } catch (e) {
      print('Error parsing PlantNet response: $e');
      return null;
    }
  }

  // 식물 종류별 최적 설정값 반환
  static Map<String, double> _getOptimalSettingsForSpecies(String species) {
    Map<String, Map<String, double>> speciesSettings = {
      'Monstera deliciosa': {
        'optimalTempMin': 18,
        'optimalTempMax': 25,
        'optimalHumidityMin': 50,
        'optimalHumidityMax': 70,
        'optimalSoilMoistureMin': 40,
        'optimalSoilMoistureMax': 60,
        'optimalLightMin': 40,
        'optimalLightMax': 70,
      },
      'Pothos aureus': {
        'optimalTempMin': 16,
        'optimalTempMax': 24,
        'optimalHumidityMin': 40,
        'optimalHumidityMax': 60,
        'optimalSoilMoistureMin': 30,
        'optimalSoilMoistureMax': 50,
        'optimalLightMin': 30,
        'optimalLightMax': 60,
      },
      'Sansevieria trifasciata': {
        'optimalTempMin': 15,
        'optimalTempMax': 28,
        'optimalHumidityMin': 30,
        'optimalHumidityMax': 50,
        'optimalSoilMoistureMin': 20,
        'optimalSoilMoistureMax': 40,
        'optimalLightMin': 20,
        'optimalLightMax': 80,
      },
      'Aloe vera': {
        'optimalTempMin': 16,
        'optimalTempMax': 30,
        'optimalHumidityMin': 20,
        'optimalHumidityMax': 40,
        'optimalSoilMoistureMin': 15,
        'optimalSoilMoistureMax': 35,
        'optimalLightMin': 60,
        'optimalLightMax': 90,
      },
      'Rhaphidophora tetrasperma': {
        'optimalTempMin': 18,
        'optimalTempMax': 26,
        'optimalHumidityMin': 50,
        'optimalHumidityMax': 70,
        'optimalSoilMoistureMin': 40,
        'optimalSoilMoistureMax': 60,
        'optimalLightMin': 40,
        'optimalLightMax': 70,
      },
      'Monstera adansonii': {
        'optimalTempMin': 18,
        'optimalTempMax': 26,
        'optimalHumidityMin': 50,
        'optimalHumidityMax': 70,
        'optimalSoilMoistureMin': 40,
        'optimalSoilMoistureMax': 60,
        'optimalLightMin': 30,
        'optimalLightMax': 65,
      },
    };

    // 해당 종의 설정이 있으면 반환, 없으면 기본값 반환
    return speciesSettings[species] ?? {
      'optimalTempMin': 18,
      'optimalTempMax': 25,
      'optimalHumidityMin': 40,
      'optimalHumidityMax': 70,
      'optimalSoilMoistureMin': 40,
      'optimalSoilMoistureMax': 70,
      'optimalLightMin': 60,
      'optimalLightMax': 90,
    };
  }
}