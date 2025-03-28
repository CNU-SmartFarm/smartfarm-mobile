import 'dart:async';
import 'dart:math';
import '../models/plant.dart';
import '../models/plant_species.dart';
import '../models/sensor_data.dart';

/// 테스트용 더미 API 서비스
/// 백엔드 없이도 앱을 테스트할 수 있도록 더미 데이터를 제공합니다.
class MockApiService {
  // 싱글톤 패턴 구현
  static final MockApiService _instance = MockApiService._internal();
  factory MockApiService() => _instance;
  MockApiService._internal();

  // 내부 데이터 저장소
  final List<PlantSpecies> _species = [];
  final List<Plant> _plants = [];
  final Map<String, List<SensorData>> _sensorData = {};

  // 랜덤 값 생성기
  final Random _random = Random();

  // 테스트 데이터 생성 시간 간격
  static const Duration dataGenerationInterval = Duration(minutes: 15);

  // 초기화 여부
  bool _initialized = false;

  // 초기화 함수
  Future<void> init() async {
    if (_initialized) return;

    // 식물 종 데이터 생성
    _initSpecies();

    // 샘플 식물 생성 - 한 개만 생성하도록 수정
    _initSamplePlants();

    // 센서 데이터 초기 생성
    _initSensorData();

    _initialized = true;

    // 주기적으로 새 센서 데이터 생성 (실제 앱에서는 API 호출로 대체)
    Timer.periodic(const Duration(minutes: 1), (_) {
      _generateNewSensorData();
    });
  }

  // 식물 종 초기화
  void _initSpecies() {
    _species.addAll([
      PlantSpecies(
        id: 'sp1',
        name: '스파티필름',
        imageUrl: 'https://example.com/spathiphyllum.jpg',
        description: '스파티필름(peace lily)은 공기정화 능력이 뛰어난 관엽식물입니다. 물을 주는 시기를 알려주는 특징이 있어 초보자도 키우기 쉽습니다.',
        temperatureRange: Range(18, 25),
        humidityRange: Range(40, 60),
        lightRange: Range(500, 1000),
      ),
      PlantSpecies(
        id: 'sp2',
        name: '몬스테라',
        imageUrl: 'https://example.com/monstera.jpg',
        description: '몬스테라는 특유의 큰 잎과 구멍이 특징인 열대 식물입니다. 빠르게 성장하며 실내 공기 정화에 도움을 줍니다.',
        temperatureRange: Range(20, 30),
        humidityRange: Range(50, 70),
        lightRange: Range(800, 1500),
      ),
      PlantSpecies(
        id: 'sp3',
        name: '산세베리아',
        imageUrl: 'https://example.com/sansevieria.jpg',
        description: '산세베리아(뱀 식물)는 건조한 환경에서도 잘 자라는 다육식물입니다. 밤에도 산소를 생성하며 관리가 매우 쉽습니다.',
        temperatureRange: Range(15, 30),
        humidityRange: Range(30, 50),
        lightRange: Range(300, 800),
      ),
      PlantSpecies(
        id: 'sp4',
        name: '피카스 벤자민',
        imageUrl: 'https://example.com/ficus.jpg',
        description: '피카스 벤자민(벤자민 고무나무)은 작은 잎이 특징인 관엽식물입니다. 은은한 광택이 있는 잎이 매력적입니다.',
        temperatureRange: Range(18, 28),
        humidityRange: Range(40, 60),
        lightRange: Range(600, 1200),
      ),
      PlantSpecies(
        id: 'sp5',
        name: '아레카 야자',
        imageUrl: 'https://example.com/areca.jpg',
        description: '아레카 야자는 공기 정화 능력이 뛰어나며 습도 조절에 도움을 주는 관엽식물입니다. 키가 크게 자라 인테리어 효과가 좋습니다.',
        temperatureRange: Range(18, 24),
        humidityRange: Range(40, 60),
        lightRange: Range(500, 1000),
      ),
    ]);
  }

  // 샘플 식물 초기화 - 한 개만 생성
  void _initSamplePlants() {
    // 샘플 식물 1: 정상 범위 내 (스파티필름)
    final plant1 = Plant(
      id: '1',
      name: '거실 친구',
      speciesId: 'sp1',
    );

    // 식물은 한 개만 추가
    _plants.add(plant1);
  }

  // 초기 센서 데이터 생성
  void _initSensorData() {
    final now = DateTime.now();

    // 지난 24시간 데이터 생성 (1시간 간격)
    for (var plant in _plants) {
      List<SensorData> plantData = [];

      for (int i = 24; i >= 0; i--) {
        final timestamp = now.subtract(Duration(hours: i));

        // 식물 종류에 따라 다른 기본값과 변동폭 설정
        double baseTemp = 22;
        double baseHumidity = 50;
        double baseLight = 800;
        double variation = 0.3;  // 30% 변동폭

        // 시간에 따른 변화 시뮬레이션 (사인파)
        final hourFactor = sin(i * 0.5) * variation;

        // 각 센서값에 약간의 임의성 부여
        final temp = baseTemp + (hourFactor * 5) + (_random.nextDouble() * 2 - 1);
        final humidity = baseHumidity + (hourFactor * 15) + (_random.nextDouble() * 6 - 3);
        final light = baseLight + (hourFactor * 400) + (_random.nextDouble() * 200 - 100);

        plantData.add(SensorData(
          id: '${plant.id}-${timestamp.millisecondsSinceEpoch}',
          temperature: temp,
          humidity: humidity,
          light: light,
          timestamp: timestamp,
        ));
      }

      _sensorData[plant.id] = plantData;
    }

    // 최신 데이터로 식물 업데이트
    for (var plant in _plants) {
      final latestData = _sensorData[plant.id]?.last;
      if (latestData != null) {
        final index = _plants.indexWhere((p) => p.id == plant.id);
        if (index >= 0) {
          _plants[index] = plant.copyWith(
            latestData: latestData,
            sensorHistory: _sensorData[plant.id] ?? [],
          );
        }
      }
    }
  }

  // 새로운 센서 데이터 생성 (시간 경과에 따른 변화 시뮬레이션)
  void _generateNewSensorData() {
    final now = DateTime.now();

    for (var plant in _plants) {
      // 이전 데이터 가져오기
      final plantData = _sensorData[plant.id] ?? [];
      if (plantData.isEmpty) continue;

      final lastData = plantData.last;

      // 작은 변동폭으로 새 데이터 생성
      double newTemp = _getNextValue(lastData.temperature, 0.5, isTemperature: true, plantId: plant.id);
      double newHumidity = _getNextValue(lastData.humidity, 2.0, isHumidity: true, plantId: plant.id);
      double newLight = _getNextValue(lastData.light, 50, isLight: true, plantId: plant.id);

      // 새 센서 데이터 생성
      final newData = SensorData(
        id: '${plant.id}-${now.millisecondsSinceEpoch}',
        temperature: newTemp,
        humidity: newHumidity,
        light: newLight,
        timestamp: now,
      );

      // 24시간보다 오래된 데이터 제거
      final oneDayAgo = now.subtract(const Duration(hours: 24));
      final filteredData = plantData.where((data) => data.timestamp.isAfter(oneDayAgo)).toList();

      // 새 데이터 추가
      filteredData.add(newData);
      _sensorData[plant.id] = filteredData;

      // 식물 정보 업데이트
      final index = _plants.indexWhere((p) => p.id == plant.id);
      if (index >= 0) {
        _plants[index] = _plants[index].copyWith(
          latestData: newData,
          sensorHistory: filteredData,
        );
      }
    }
  }

  // 이전 값에서 약간 변동된 다음 값 계산
  double _getNextValue(double currentValue, double maxChange, {
    bool isTemperature = false,
    bool isHumidity = false,
    bool isLight = false,
    String? plantId,
  }) {
    // 기본 변동폭
    double change = (_random.nextDouble() * 2 - 1) * maxChange;

    // 새 값 계산
    double newValue = currentValue + change;

    // 값 범위 제한
    if (isTemperature) {
      newValue = newValue.clamp(10, 35);  // 온도 10-35도 범위 제한
    } else if (isHumidity) {
      newValue = newValue.clamp(20, 80);  // 습도 20-80% 범위 제한
    } else if (isLight) {
      newValue = newValue.clamp(200, 2000);  // 조도 200-2000 lux 범위 제한
    }

    return newValue;
  }

  // API 메서드: 모든 식물 종 목록 가져오기
  Future<List<PlantSpecies>> getSpecies() async {
    // 초기화 확인
    if (!_initialized) await init();

    // API 호출 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 800));
    return _species;
  }

  // API 메서드: 모든 식물 목록 가져오기
  Future<List<Plant>> getPlants() async {
    // 초기화 확인
    if (!_initialized) await init();

    // API 호출 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 1000));
    return _plants;
  }

  // API 메서드: 새 식물 등록하기
  Future<Plant> addPlant(Plant plant) async {
    // 초기화 확인
    if (!_initialized) await init();

    // API 호출 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 1200));

    // 이미 식물이 있는지 확인
    if (_plants.isNotEmpty) {
      throw Exception('식물은 한 개만 추가할 수 있습니다.');
    }

    // 새 식물에 ID 부여
    final newPlant = Plant(
      id: (DateTime.now().millisecondsSinceEpoch % 10000).toString(),
      name: plant.name,
      speciesId: plant.speciesId,
    );

    // 식물 목록에 추가
    _plants.add(newPlant);

    // 초기 센서 데이터 생성
    final now = DateTime.now();
    final List<SensorData> initialData = [];

    // 지난 24시간 데이터 생성 (1시간 간격)
    for (int i = 24; i >= 0; i--) {
      final timestamp = now.subtract(Duration(hours: i));

      initialData.add(SensorData(
        id: '${newPlant.id}-${timestamp.millisecondsSinceEpoch}',
        temperature: 22 + (_random.nextDouble() * 6 - 3),
        humidity: 50 + (_random.nextDouble() * 20 - 10),
        light: 800 + (_random.nextDouble() * 400 - 200),
        timestamp: timestamp,
      ));
    }

    // 최신 데이터 저장
    _sensorData[newPlant.id] = initialData;

    // 최신 데이터로 식물 정보 업데이트
    final latestData = initialData.last;
    final index = _plants.indexWhere((p) => p.id == newPlant.id);
    if (index >= 0) {
      _plants[index] = newPlant.copyWith(
        latestData: latestData,
        sensorHistory: initialData,
      );
      return _plants[index];
    }

    return newPlant;
  }

  // API 메서드: 특정 식물의 센서 데이터 가져오기
  Future<List<SensorData>> getPlantData(String plantId) async {
    // 초기화 확인
    if (!_initialized) await init();

    // API 호출 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 900));
    return _sensorData[plantId] ?? [];
  }

  // API 메서드: 특정 식물의 최신 센서 데이터만 가져오기
  Future<SensorData?> getLatestData(String plantId) async {
    // 초기화 확인
    if (!_initialized) await init();

    // API 호출 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));
    final data = _sensorData[plantId];
    return data?.isNotEmpty == true ? data!.last : null;
  }
}