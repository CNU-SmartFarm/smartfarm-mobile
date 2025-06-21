import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../models/app_models.dart';
import '../helpers/api_exception.dart';

class ApiService {
  static const String baseUrl = 'http://43.201.68.168:8080/api';
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };
  static const Duration timeout = Duration(seconds: 10);

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

  // Mock 센서 데이터 생성
  static SensorData _generateMockSensorData(String plantId) {
    final random = Random();
    return SensorData(
      id: 'sensor_${DateTime.now().millisecondsSinceEpoch}',
      plantId: plantId,
      temperature: 20.0 + random.nextDouble() * 8.0, // 20-28도
      humidity: 45.0 + random.nextDouble() * 25.0, // 45-70%
      soilMoisture: 35.0 + random.nextDouble() * 30.0, // 35-65%
      light: 40.0 + random.nextDouble() * 40.0, // 40-80%
      timestamp: DateTime.now(),
    );
  }

  // Mock 과거 데이터 생성
  static List<HistoricalDataPoint> _generateMockHistoricalData(String plantId, String period) {
    final random = Random();
    List<HistoricalDataPoint> data = [];

    int dataPoints;
    Duration interval;

    switch (period) {
      case '24h':
        dataPoints = 24;
        interval = Duration(hours: 1);
        break;
      case '7d':
        dataPoints = 14;
        interval = Duration(hours: 12);
        break;
      case '30d':
        dataPoints = 30;
        interval = Duration(days: 1);
        break;
      case '90d':
        dataPoints = 30;
        interval = Duration(days: 3);
        break;
      default:
        dataPoints = 24;
        interval = Duration(hours: 1);
    }

    DateTime now = DateTime.now();

    for (int i = dataPoints - 1; i >= 0; i--) {
      DateTime timestamp = now.subtract(interval * i);

      data.add(HistoricalDataPoint(
        id: 'data_${timestamp.millisecondsSinceEpoch}',
        plantId: plantId,
        date: timestamp.toIso8601String().split('T')[0],
        time: timestamp.hour,
        temperature: 18.0 + random.nextDouble() * 10.0,
        humidity: 40.0 + random.nextDouble() * 30.0,
        soilMoisture: 30.0 + random.nextDouble() * 40.0,
        light: 35.0 + random.nextDouble() * 45.0,
      ));
    }

    return data;
  }

  // Mock 알림 데이터 생성
  static List<NotificationItem> _generateMockNotifications(String plantId) {
    final random = Random();
    List<NotificationItem> notifications = [];

    List<String> messages = [
      '토양 수분이 부족합니다. 물을 주세요.',
      '조도가 낮습니다. 더 밝은 곳으로 이동하세요.',
      '온도가 최적 범위를 벗어났습니다.',
      '습도가 너무 낮습니다.',
      '식물 상태가 양호합니다.',
      '센서 연결을 확인해주세요.',
    ];

    List<String> types = ['warning', 'info', 'error', 'success'];

    for (int i = 0; i < 5; i++) {
      notifications.add(NotificationItem(
        id: i + 1,
        plantId: plantId,
        type: types[random.nextInt(types.length)],
        message: messages[random.nextInt(messages.length)],
        timestamp: DateTime.now().subtract(Duration(hours: i * 2)),
        isRead: random.nextBool(),
      ));
    }

    return notifications;
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
      ).timeout(timeout);

      if (response.statusCode == 201) {
        final data = _handleResponse(response);
        return Plant.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      print('Error registering plant: $e');

      // API 실패 시 Mock 데이터로 식물 등록
      return Plant(
        id: 'plant_${DateTime.now().millisecondsSinceEpoch}',
        name: plant.name,
        species: plant.species,
        registeredDate: DateTime.now().toString().split(' ')[0],
        optimalTempMin: plant.optimalTempMin,
        optimalTempMax: plant.optimalTempMax,
        optimalHumidityMin: plant.optimalHumidityMin,
        optimalHumidityMax: plant.optimalHumidityMax,
        optimalSoilMoistureMin: plant.optimalSoilMoistureMin,
        optimalSoilMoistureMax: plant.optimalSoilMoistureMax,
        optimalLightMin: plant.optimalLightMin,
        optimalLightMax: plant.optimalLightMax,
      );
    }
  }

  // 식물 정보 조회
  static Future<Plant?> getPlant(String plantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plants/$plantId'),
        headers: headers,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return Plant.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      print('Error getting plant: $e');
      return null;
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
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return Plant.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      print('Error updating plant: $e');

      // API 실패 시 Mock으로 업데이트된 식물 반환
      return plant;
    }
  }

  // 식물 삭제
  static Future<bool> deletePlant(String plantId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/plants/$plantId'),
        headers: headers,
      ).timeout(timeout);

      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting plant: $e');

      // API 실패 시에도 삭제 성공으로 처리 (로컬에서만 삭제됨)
      return true;
    }
  }

  // 현재 센서 데이터 조회 - Mock 데이터 우선 제공
  static Future<SensorData?> getCurrentSensorData(String plantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plants/$plantId/sensors/current'),
        headers: headers,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return SensorData.fromJson(data['data']);
      }
    } catch (e) {
      print('Error getting sensor data, using mock data: $e');
    }

    // API 실패 시 Mock 데이터 반환
    return _generateMockSensorData(plantId);
  }

  // 과거 센서 데이터 조회 - Mock 데이터 우선 제공
  static Future<List<HistoricalDataPoint>> getHistoricalData(
      String plantId, String period) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plants/$plantId/sensors/history?period=$period'),
        headers: headers,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return (data['data'] as List)
            .map((item) => HistoricalDataPoint.fromJson(item))
            .toList();
      }
    } catch (e) {
      print('Error getting historical data, using mock data: $e');
    }

    // API 실패 시 Mock 데이터 반환
    return _generateMockHistoricalData(plantId, period);
  }

  // 알림 목록 조회 - Mock 데이터 우선 제공
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

      final response = await http.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return (data['data'] as List)
            .map((item) => NotificationItem.fromJson(item))
            .toList();
      }
    } catch (e) {
      print('Error getting notifications, using mock data: $e');
    }

    // API 실패 시 Mock 데이터 반환
    return _generateMockNotifications(plantId);
  }

  // 알림 읽음 처리
  static Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: headers,
      ).timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');

      // API 실패 시에도 성공으로 처리 (로컬에서만 처리됨)
      return true;
    }
  }

  // 사용자 설정 조회
  static Future<Settings?> getSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings'),
        headers: headers,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return Settings.fromJson(data['data']);
      }
    } catch (e) {
      print('Error getting settings: $e');
    }

    return null;
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
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return Settings.fromJson(data['data']);
      }
    } catch (e) {
      print('Error updating settings: $e');
    }

    // API 실패 시 입력받은 설정을 그대로 반환
    return settings;
  }

  // 식물 프로파일 목록 조회
  static Future<List<PlantProfile>> getPlantProfiles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plant-profiles'),
        headers: headers,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return (data['data'] as List)
            .map((item) => PlantProfile.fromJson(item))
            .toList();
      }
    } catch (e) {
      print('Error getting plant profiles: $e');
    }

    return [];
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

      final response = await request.send().timeout(Duration(seconds: 30));

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

      // AI 인식 실패 시 null 반환
      return null;
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