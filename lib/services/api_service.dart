import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../models/app_models.dart';
import '../helpers/api_exception.dart';

class ApiService {
  static const String baseUrl = 'http://43.201.68.168:8080/api';
  static const Duration timeoutDuration = Duration(seconds: 30);

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // HTTP 클라이언트 설정
  static http.Client get _client {
    return http.Client();
  }

  // 응답 처리 헬퍼 메서드
  static Map<String, dynamic> _handleResponse(http.Response response) {
    print('API Response [${response.statusCode}]: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          return {'data': decoded};
        }
      } catch (e) {
        print('JSON decode error: $e');
        throw ApiException('Invalid JSON response', statusCode: response.statusCode);
      }
    } else {
      String errorMessage = 'API request failed';
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody is Map<String, dynamic>) {
          errorMessage = errorBody['message'] ?? errorBody['error'] ?? errorMessage;
        }
      } catch (e) {
        errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
      }

      throw ApiException(
        errorMessage,
        statusCode: response.statusCode,
        errorCode: response.statusCode.toString(),
      );
    }
  }

  // 식물 등록
  static Future<Plant?> registerPlant(Plant plant) async {
    try {
      print('Registering plant: ${plant.name}');

      final client = _client;
      final response = await client.post(
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
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data.containsKey('data') || data.containsKey('id')) {
        return Plant.fromJson(data['data'] ?? data);
      }

      return null;
    } on SocketException {
      throw ApiException('네트워크 연결을 확인해주세요.');
    } on HttpException {
      throw ApiException('서버 연결에 실패했습니다.');
    } catch (e) {
      print('Error registering plant: $e');
      if (e is ApiException) rethrow;
      throw ApiException('식물 등록에 실패했습니다: $e');
    }
  }

  // 식물 정보 조회
  static Future<Plant?> getPlant(String plantId) async {
    try {
      print('Getting plant: $plantId');

      final client = _client;
      final response = await client.get(
        Uri.parse('$baseUrl/plants/$plantId'),
        headers: headers,
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data.containsKey('data') || data.containsKey('id')) {
        return Plant.fromJson(data['data'] ?? data);
      }

      return null;
    } on SocketException {
      throw ApiException('네트워크 연결을 확인해주세요.');
    } catch (e) {
      print('Error getting plant: $e');
      if (e is ApiException) rethrow;
      throw ApiException('식물 정보를 가져오는데 실패했습니다: $e');
    }
  }

  // 전체 식물 목록 조회
  static Future<List<Plant>> getAllPlants() async {
    try {
      print('Getting all plants');

      final client = _client;
      final response = await client.get(
        Uri.parse('$baseUrl/plants'),
        headers: headers,
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data.containsKey('data') && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => Plant.fromJson(item))
            .toList();
      }

      return [];
    } on SocketException {
      throw ApiException('네트워크 연결을 확인해주세요.');
    } catch (e) {
      print('Error getting plants: $e');
      if (e is ApiException) rethrow;
      throw ApiException('식물 목록을 가져오는데 실패했습니다: $e');
    }
  }

  // 식물 정보 수정
  static Future<Plant?> updatePlant(String plantId, Plant plant) async {
    try {
      print('Updating plant: $plantId');

      final client = _client;
      final response = await client.put(
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
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data.containsKey('data') || data.containsKey('id')) {
        return Plant.fromJson(data['data'] ?? data);
      }

      return null;
    } on SocketException {
      throw ApiException('네트워크 연결을 확인해주세요.');
    } catch (e) {
      print('Error updating plant: $e');
      if (e is ApiException) rethrow;
      throw ApiException('식물 정보 수정에 실패했습니다: $e');
    }
  }

  // 식물 삭제
  static Future<bool> deletePlant(String plantId) async {
    try {
      print('Deleting plant: $plantId');

      final client = _client;
      final response = await client.delete(
        Uri.parse('$baseUrl/plants/$plantId'),
        headers: headers,
      ).timeout(timeoutDuration);

      return response.statusCode == 200 || response.statusCode == 204;
    } on SocketException {
      throw ApiException('네트워크 연결을 확인해주세요.');
    } catch (e) {
      print('Error deleting plant: $e');
      if (e is ApiException) rethrow;
      throw ApiException('식물 삭제에 실패했습니다: $e');
    }
  }

  // 현재 센서 데이터 조회
  static Future<SensorData?> getCurrentSensorData(String plantId) async {
    try {
      print('Getting current sensor data for plant: $plantId');

      final client = _client;
      final response = await client.get(
        Uri.parse('$baseUrl/plants/$plantId/sensors/current'),
        headers: headers,
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data.containsKey('data') || data.containsKey('id')) {
        return SensorData.fromJson(data['data'] ?? data);
      }

      return null;
    } on SocketException {
      throw ApiException('네트워크 연결을 확인해주세요.');
    } catch (e) {
      print('Error getting sensor data: $e');
      if (e is ApiException) rethrow;
      throw ApiException('센서 데이터를 가져오는데 실패했습니다: $e');
    }
  }

  // 과거 센서 데이터 조회
  static Future<List<HistoricalDataPoint>> getHistoricalData(
      String plantId, String period) async {
    try {
      print('Getting historical data for plant: $plantId, period: $period');

      final client = _client;
      final response = await client.get(
        Uri.parse('$baseUrl/plants/$plantId/sensors/history?period=$period'),
        headers: headers,
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data.containsKey('data') && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => HistoricalDataPoint.fromJson(item))
            .toList();
      }

      return [];
    } on SocketException {
      throw ApiException('네트워크 연결을 확인해주세요.');
    } catch (e) {
      print('Error getting historical data: $e');
      if (e is ApiException) rethrow;
      throw ApiException('과거 데이터를 가져오는데 실패했습니다: $e');
    }
  }

  // 센서 데이터 전송 (IoT 디바이스용)
  static Future<bool> uploadSensorData(String plantId, SensorData sensorData) async {
    try {
      print('Uploading sensor data for plant: $plantId');

      final client = _client;
      final response = await client.post(
        Uri.parse('$baseUrl/plants/$plantId/sensors'),
        headers: headers,
        body: jsonEncode({
          'temperature': sensorData.temperature,
          'humidity': sensorData.humidity,
          'soilMoisture': sensorData.soilMoisture,
          'light': sensorData.light,
          'timestamp': sensorData.timestamp.toIso8601String(),
        }),
      ).timeout(timeoutDuration);

      return response.statusCode >= 200 && response.statusCode < 300;
    } on SocketException {
      throw ApiException('네트워크 연결을 확인해주세요.');
    } catch (e) {
      print('Error uploading sensor data: $e');
      if (e is ApiException) rethrow;
      throw ApiException('센서 데이터 전송에 실패했습니다: $e');
    }
  }

  // 알림 목록 조회
  static Future<List<NotificationItem>> getNotifications(String plantId,
      {int limit = 20, int offset = 0, bool unreadOnly = false}) async {
    try {
      print('Getting notifications for plant: $plantId');

      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (unreadOnly) 'unreadOnly': 'true',
      };

      final uri = Uri.parse('$baseUrl/plants/$plantId/notifications')
          .replace(queryParameters: queryParams);

      final client = _client;
      final response = await client.get(uri, headers: headers).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data.containsKey('data') && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => NotificationItem.fromJson(item))
            .toList();
      }

      return [];
    } on SocketException {
      throw ApiException('네트워크 연결을 확인해주세요.');
    } catch (e) {
      print('Error getting notifications: $e');
      if (e is ApiException) rethrow;
      throw ApiException('알림을 가져오는데 실패했습니다: $e');
    }
  }

  // 알림 읽음 처리
  static Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      print('Marking notification as read: $notificationId');

      final client = _client;
      final response = await client.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: headers,
      ).timeout(timeoutDuration);

      return response.statusCode >= 200 && response.statusCode < 300;
    } on SocketException {
      throw ApiException('네트워크 연결을 확인해주세요.');
    } catch (e) {
      print('Error marking notification as read: $e');
      if (e is ApiException) rethrow;
      throw ApiException('알림 읽음 처리에 실패했습니다: $e');
    }
  }

  // 사용자 설정 조회
  static Future<Settings?> getSettings() async {
    try {
      print('Getting user settings');

      final client = _client;
      final response = await client.get(
        Uri.parse('$baseUrl/settings'),
        headers: headers,
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data.containsKey('data') || data.containsKey('userId')) {
        return Settings.fromJson(data['data'] ?? data);
      }

      return null;
    } on SocketException {
      throw ApiException('네트워크 연결을 확인해주세요.');
    } catch (e) {
      print('Error getting settings: $e');
      if (e is ApiException) rethrow;
      throw ApiException('설정을 가져오는데 실패했습니다: $e');
    }
  }

  // 사용자 설정 업데이트
  static Future<Settings?> updateSettings(Settings settings) async {
    try {
      print('Updating user settings');

      final client = _client;
      final response = await client.put(
        Uri.parse('$baseUrl/settings'),
        headers: headers,
        body: jsonEncode({
          'pushNotificationEnabled': settings.pushNotificationEnabled,
          'language': settings.language,
          'theme': settings.theme,
        }),
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data.containsKey('data') || data.containsKey('userId')) {
        return Settings.fromJson(data['data'] ?? data);
      }

      return null;
    } on SocketException {
      throw ApiException('네트워크 연결을 확인해주세요.');
    } catch (e) {
      print('Error updating settings: $e');
      if (e is ApiException) rethrow;
      throw ApiException('설정 업데이트에 실패했습니다: $e');
    }
  }

  // 식물 프로파일 목록 조회
  static Future<List<PlantProfile>> getPlantProfiles() async {
    try {
      print('Getting plant profiles');

      final client = _client;
      final response = await client.get(
        Uri.parse('$baseUrl/plant-profiles'),
        headers: headers,
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data.containsKey('data') && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => PlantProfile.fromJson(item))
            .toList();
      }

      return [];
    } on SocketException {
      throw ApiException('네트워크 연결을 확인해주세요.');
    } catch (e) {
      print('Error getting plant profiles: $e');
      if (e is ApiException) rethrow;
      throw ApiException('식물 프로파일을 가져오는데 실패했습니다: $e');
    }
  }

  // AI 식물 인식 (PlantNet API 사용)
  static Future<AIIdentificationResult?> identifyPlant(File imageFile) async {
    try {
      print('Identifying plant with AI');

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

      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parsePlantNetResponse(data);
      } else {
        print('PlantNet API Error: ${response.statusCode} - ${response.body}');
        throw ApiException('AI 인식 서비스 오류 (${response.statusCode})');
      }
    } on SocketException {
      throw ApiException('네트워크 연결을 확인해주세요.');
    } catch (e) {
      print('Error identifying plant: $e');
      if (e is ApiException) rethrow;
      throw ApiException('AI 식물 인식에 실패했습니다: $e');
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

  // 연결 테스트
  static Future<bool> testConnection() async {
    try {
      print('Testing API connection');

      final client = _client;
      final response = await client.get(
        Uri.parse('$baseUrl/health'),
        headers: headers,
      ).timeout(Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // 리소스 정리
  static void dispose() {
    // 필요시 클린업 로직 추가
  }
}