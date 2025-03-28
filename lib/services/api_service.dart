import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant.dart';
import '../models/plant_species.dart';
import '../models/sensor_data.dart';

class ApiService {
  // API 기본 URL (실제 환경에 맞게 조정 필요)
  static const String baseUrl = 'https://your-api-endpoint.com/api';

  // API 엔드포인트
  static const String _plantsEndpoint = '/plants';
  static const String _speciesEndpoint = '/species';

  // 모든 식물 종 목록 가져오기
  Future<List<PlantSpecies>> getSpecies() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$_speciesEndpoint'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PlantSpecies.fromJson(json)).toList();
      } else {
        throw Exception('식물 종 정보를 불러오는데 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      // 네트워크 오류 발생 시 기본 식물 종 목록 제공 (개발 테스트용)
      return _getDefaultSpecies();
    }
  }

  // 모든 식물 목록 가져오기
  Future<List<Plant>> getPlants() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$_plantsEndpoint'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final plants = data.map((json) => Plant.fromJson(json)).toList();

        // 서버에서 여러 식물이 반환되더라도 첫 번째 식물만 사용
        return plants.isEmpty ? [] : [plants.first];
      } else {
        throw Exception('식물 목록을 불러오는데 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      // 에러 발생 시 로컬에 저장된 식물 목록 반환
      return _getLocalPlants();
    }
  }

  // 새 식물 등록하기
  Future<Plant> addPlant(Plant plant) async {
    try {
      // 이미 식물이 있는지 확인
      final existingPlants = await _getLocalPlants();
      if (existingPlants.isNotEmpty) {
        throw Exception('식물은 한 개만 추가할 수 있습니다.');
      }

      final response = await http.post(
        Uri.parse('$baseUrl$_plantsEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(plant.toPostJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        Plant newPlant = Plant.fromJson(data);

        // 로컬에도 저장
        _saveLocalPlant(newPlant);

        return newPlant;
      } else {
        throw Exception('식물 등록에 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      // 이미 식물이 있는 경우 예외 전달
      if (e.toString().contains('식물은 한 개만 추가할 수 있습니다')) {
        rethrow;
      }

      // 개발 테스트용: 네트워크 오류 시 임시 ID 생성하여 로컬에만 저장
      final tempPlant = Plant(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: plant.name,
        speciesId: plant.speciesId,
      );

      // 로컬에 저장
      _saveLocalPlant(tempPlant);

      return tempPlant;
    }
  }

  // 특정 식물의 센서 데이터 가져오기
  Future<List<SensorData>> getPlantData(String plantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$_plantsEndpoint/$plantId/data'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SensorData.fromJson(json)).toList();
      } else {
        throw Exception('센서 데이터를 불러오는데 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      // 개발 테스트용: 네트워크 오류 시 더미 데이터 생성
      return _generateDummySensorData();
    }
  }

  // 특정 식물의 최신 센서 데이터만 가져오기 (백그라운드 모니터링용)
  Future<SensorData?> getLatestData(String plantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$_plantsEndpoint/$plantId/latest'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SensorData.fromJson(data);
      } else if (response.statusCode == 404) {
        // 데이터가 없는 경우
        return null;
      } else {
        throw Exception('최신 센서 데이터를 불러오는데 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      // 개발 테스트용: 네트워크 오류 시 랜덤 데이터 반환
      return _generateRandomSensorData();
    }
  }

  // 로컬에 저장된 식물 목록 가져오기
  Future<List<Plant>> _getLocalPlants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plantsJson = prefs.getStringList('plants') ?? [];

      final plants = plantsJson
          .map((plantStr) => Plant.fromJson(json.decode(plantStr)))
          .toList();

      // 여러 식물이 저장되어 있더라도 첫 번째 식물만 반환
      return plants.isEmpty ? [] : [plants.first];
    } catch (e) {
      return [];
    }
  }

  // 식물 정보를 로컬에 저장하기
  Future<void> _saveLocalPlant(Plant plant) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 기존 식물 목록을 지우고 새 식물만 저장
      await prefs.setStringList('plants', [json.encode(plant.toJson())]);
    } catch (e) {
      // 저장 실패 시 로그만 출력
      print('로컬 저장 실패: $e');
    }
  }

  // 개발 테스트용: 기본 식물 종 목록
  List<PlantSpecies> _getDefaultSpecies() {
    return [
      PlantSpecies(
        id: 'sp1',
        name: '스파티필름',
        imageUrl: 'https://example.com/spathiphyllum.jpg',
        description: '스파티필름(peace lily)은 공기정화 능력이 뛰어난 관엽식물입니다.',
        temperatureRange: Range(18, 25),
        humidityRange: Range(40, 60),
        lightRange: Range(500, 1000),
      ),
      PlantSpecies(
        id: 'sp2',
        name: '몬스테라',
        imageUrl: 'https://example.com/monstera.jpg',
        description: '몬스테라는 특유의 큰 잎과 구멍이 특징인 열대 식물입니다.',
        temperatureRange: Range(20, 30),
        humidityRange: Range(50, 70),
        lightRange: Range(800, 1500),
      ),
      PlantSpecies(
        id: 'sp3',
        name: '산세베리아',
        imageUrl: 'https://example.com/sansevieria.jpg',
        description: '산세베리아(뱀 식물)는 건조한 환경에서도 잘 자라는 다육식물입니다.',
        temperatureRange: Range(15, 30),
        humidityRange: Range(30, 50),
        lightRange: Range(300, 800),
      ),
      PlantSpecies(
        id: 'sp4',
        name: '피카스 벤자민',
        imageUrl: 'https://example.com/ficus.jpg',
        description: '피카스 벤자민(벤자민 고무나무)은 작은 잎이 특징인 관엽식물입니다.',
        temperatureRange: Range(18, 28),
        humidityRange: Range(40, 60),
        lightRange: Range(600, 1200),
      ),
    ];
  }

  // 개발 테스트용: 더미 센서 데이터 생성
  List<SensorData> _generateDummySensorData() {
    final List<SensorData> dummyData = [];
    final now = DateTime.now();

    // 24시간 데이터 생성 (1시간 간격)
    for (int i = 24; i >= 0; i--) {
      final timestamp = now.subtract(Duration(hours: i));

      dummyData.add(SensorData(
        id: timestamp.millisecondsSinceEpoch.toString(),
        temperature: 20 + (5 * _randomDouble()),
        humidity: 50 + (20 * _randomDouble()),
        light: 800 + (400 * _randomDouble()),
        timestamp: timestamp,
      ));
    }

    return dummyData;
  }

  // 개발 테스트용: 랜덤 센서 데이터 생성
  SensorData _generateRandomSensorData() {
    return SensorData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      temperature: 20 + (5 * _randomDouble()),
      humidity: 50 + (20 * _randomDouble()),
      light: 800 + (400 * _randomDouble()),
      timestamp: DateTime.now(),
    );
  }

  // -1.0과 1.0 사이의 랜덤 값 생성
  double _randomDouble() {
    return (DateTime.now().millisecondsSinceEpoch % 200 - 100) / 100;
  }
}