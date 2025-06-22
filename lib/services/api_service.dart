import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../models/plant.dart';
import '../models/sensor_data.dart';
import '../models/notification_item.dart';
import '../models/historical_data_point.dart';
import '../models/settings.dart';
import '../models/plant_profile.dart';
import '../models/ai_identification_result.dart';
import '../helpers/api_exception.dart';

class ApiService {
  static const String baseUrl = 'http://43.201.68.168:8080/api';
  static const Duration timeoutDuration = Duration(seconds: 30);

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 응답 처리 헬퍼 메서드
  static Map<String, dynamic> _handleResponse(http.Response response) {
    print('API Response [${response.statusCode}]: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }

      try {
        final decoded = jsonDecode(response.body);
        return decoded;
      } catch (e) {
        throw ApiException('Invalid JSON response', statusCode: response.statusCode);
      }
    } else {
      String errorMessage = 'API request failed';
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody['error'] != null) {
          errorMessage = errorBody['error']['message'] ?? errorMessage;
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
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data['success'] == true && data['data'] != null) {
        return Plant.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('식물 등록에 실패했습니다: $e');
    }
  }

  // 식물 정보 조회
  static Future<Plant?> getPlant(String plantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plants/$plantId'),
        headers: headers,
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data['success'] == true && data['data'] != null) {
        return Plant.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('식물 정보를 가져오는데 실패했습니다: $e');
    }
  }

  // 전체 식물 목록 조회
  static Future<List<Plant>> getAllPlants() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plants'),
        headers: headers,
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((item) => Plant.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('식물 목록을 가져오는데 실패했습니다: $e');
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
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data['success'] == true && data['data'] != null) {
        return Plant.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('식물 정보 수정에 실패했습니다: $e');
    }
  }

  // 식물 삭제
  static Future<bool> deletePlant(String plantId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/plants/$plantId'),
        headers: headers,
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      return data['success'] == true;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('식물 삭제에 실패했습니다: $e');
    }
  }

  // 현재 센서 데이터 조회
  static Future<SensorData?> getCurrentSensorData(String plantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plants/$plantId/sensors/current'),
        headers: headers,
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data['success'] == true && data['data'] != null) {
        return SensorData.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('센서 데이터를 가져오는데 실패했습니다: $e');
    }
  }

  // 과거 센서 데이터 조회
  static Future<List<HistoricalDataPoint>> getHistoricalData(String plantId, String period) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plants/$plantId/sensors/history?period=$period'),
        headers: headers,
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((item) => HistoricalDataPoint.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('과거 데이터를 가져오는데 실패했습니다: $e');
    }
  }

  // 센서 데이터 전송 (IoT 디바이스용)
  static Future<bool> uploadSensorData(String plantId, SensorData sensorData) async {
    try {
      final response = await http.post(
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
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('센서 데이터 전송에 실패했습니다: $e');
    }
  }

  // 알림 목록 조회
  static Future<List<NotificationItem>> getNotifications(String plantId, {int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plants/$plantId/notifications?limit=$limit'),
        headers: headers,
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((item) => NotificationItem.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('알림을 가져오는데 실패했습니다: $e');
    }
  }

  // 알림 읽음 처리
  static Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: headers,
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      return data['success'] == true;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('알림 읽음 처리에 실패했습니다: $e');
    }
  }

  // 사용자 설정 조회
  static Future<Settings?> getSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings'),
        headers: headers,
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data['success'] == true && data['data'] != null) {
        return Settings.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('설정을 가져오는데 실패했습니다: $e');
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
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data['success'] == true && data['data'] != null) {
        return Settings.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('설정 업데이트에 실패했습니다: $e');
    }
  }

  // 식물 프로파일 목록 조회
  static Future<List<PlantProfile>> getPlantProfiles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plant-profiles'),
        headers: headers,
      ).timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((item) => PlantProfile.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('식물 프로파일을 가져오는데 실패했습니다: $e');
    }
  }

  // AI 식물 인식
  static Future<AIIdentificationResult?> identifyPlant(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/plants/identify'));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      final data = _handleResponse(response);
      if (data['success'] == true && data['data'] != null) {
        return AIIdentificationResult.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('AI 식물 인식에 실패했습니다: $e');
    }
  }

  // 연결 테스트
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: headers,
      ).timeout(Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}