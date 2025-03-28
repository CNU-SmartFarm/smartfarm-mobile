import 'package:flutter/foundation.dart';
import 'sensor_data.dart';
import 'plant_species.dart';

class Plant {
  final String id;
  final String name; // 사용자 정의 이름
  final String speciesId; // 식물 종 ID
  final List<SensorData> sensorHistory; // 센서 데이터 기록
  final SensorData? latestData; // 최신 센서 데이터

  Plant({
    required this.id,
    required this.name,
    required this.speciesId,
    this.sensorHistory = const [],
    this.latestData,
  });

  // JSON에서 식물 객체 생성
  factory Plant.fromJson(Map<String, dynamic> json) {
    // 센서 데이터 기록이 있는 경우 파싱
    List<SensorData> history = [];
    if (json['sensorHistory'] != null) {
      history = (json['sensorHistory'] as List)
          .map((data) => SensorData.fromJson(data))
          .toList();
    }

    // 최신 데이터가 있는 경우 파싱
    SensorData? latest;
    if (json['latestData'] != null) {
      latest = SensorData.fromJson(json['latestData']);
    }

    return Plant(
      id: json['id'],
      name: json['name'],
      speciesId: json['speciesId'],
      sensorHistory: history,
      latestData: latest,
    );
  }

  // 식물 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'speciesId': speciesId,
    };
  }

  // 백엔드에 새 식물 등록할 때 사용할 JSON
  Map<String, dynamic> toPostJson() {
    return {
      'name': name,
      'speciesId': speciesId,
    };
  }

  // 객체 복사 및 업데이트
  Plant copyWith({
    String? id,
    String? name,
    String? speciesId,
    List<SensorData>? sensorHistory,
    SensorData? latestData,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      speciesId: speciesId ?? this.speciesId,
      sensorHistory: sensorHistory ?? this.sensorHistory,
      latestData: latestData ?? this.latestData,
    );
  }

  // 최신 센서 데이터 업데이트
  Plant updateWithLatestData(SensorData data) {
    List<SensorData> updatedHistory = List.from(sensorHistory);
    // 24시간 이내의 데이터만 유지
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(hours: 24));

    // 24시간 이내의 데이터만 필터링
    updatedHistory = updatedHistory
        .where((data) => data.timestamp.isAfter(oneDayAgo))
        .toList();

    // 새 데이터 추가
    updatedHistory.add(data);

    return copyWith(
      sensorHistory: updatedHistory,
      latestData: data,
    );
  }

  // 특정 식물 종에 따른 환경 적합성 확인
  bool isEnvironmentSuitable(PlantSpecies species) {
    if (latestData == null) return true; // 데이터가 없으면 항상 적합하다고 가정

    bool tempOk = species.temperatureRange.isInRange(latestData!.temperature);
    bool humidityOk = species.humidityRange.isInRange(latestData!.humidity);
    bool lightOk = species.lightRange.isInRange(latestData!.light);

    return tempOk && humidityOk && lightOk;
  }

  // 현재 환경이 적합하지 않을 경우 알림 메시지 생성
  String? generateAlertMessage(PlantSpecies species) {
    if (latestData == null) return null;

    List<String> alerts = [];

    if (!species.temperatureRange.isInRange(latestData!.temperature)) {
      if (latestData!.temperature < species.temperatureRange.min) {
        alerts.add('온도가 너무 낮습니다 (현재 ${latestData!.temperature.toStringAsFixed(1)}°C, 적정 ${species.temperatureRange.min}-${species.temperatureRange.max}°C)');
      } else {
        alerts.add('온도가 너무 높습니다 (현재 ${latestData!.temperature.toStringAsFixed(1)}°C, 적정 ${species.temperatureRange.min}-${species.temperatureRange.max}°C)');
      }
    }

    if (!species.humidityRange.isInRange(latestData!.humidity)) {
      if (latestData!.humidity < species.humidityRange.min) {
        alerts.add('습도가 너무 낮습니다 (현재 ${latestData!.humidity.toStringAsFixed(1)}%, 적정 ${species.humidityRange.min}-${species.humidityRange.max}%)');
      } else {
        alerts.add('습도가 너무 높습니다 (현재 ${latestData!.humidity.toStringAsFixed(1)}%, 적정 ${species.humidityRange.min}-${species.humidityRange.max}%)');
      }
    }

    if (!species.lightRange.isInRange(latestData!.light)) {
      if (latestData!.light < species.lightRange.min) {
        alerts.add('조도가 너무 낮습니다 (현재 ${latestData!.light.toStringAsFixed(0)} lux, 적정 ${species.lightRange.min.toInt()}-${species.lightRange.max.toInt()} lux)');
      } else {
        alerts.add('조도가 너무 높습니다 (현재 ${latestData!.light.toStringAsFixed(0)} lux, 적정 ${species.lightRange.min.toInt()}-${species.lightRange.max.toInt()} lux)');
      }
    }

    if (alerts.isEmpty) return null;

    return '${species.name} \'$name\' ${alerts.join(', ')}';
  }
}