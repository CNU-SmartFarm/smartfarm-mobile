class Range {
  final double min;
  final double max;

  Range(this.min, this.max);

  bool isInRange(double value) => value >= min && value <= max;

  factory Range.fromJson(Map<String, dynamic> json) {
    return Range(
      json['min'].toDouble(),
      json['max'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
    };
  }
}

class PlantSpecies {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final Range temperatureRange;  // 적정 온도 범위
  final Range humidityRange;     // 적정 습도 범위
  final Range lightRange;        // 적정 조도 범위

  PlantSpecies({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.temperatureRange,
    required this.humidityRange,
    required this.lightRange,
  });

  factory PlantSpecies.fromJson(Map<String, dynamic> json) {
    return PlantSpecies(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      temperatureRange: Range.fromJson(json['temperatureRange']),
      humidityRange: Range.fromJson(json['humidityRange']),
      lightRange: Range.fromJson(json['lightRange']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'temperatureRange': temperatureRange.toJson(),
      'humidityRange': humidityRange.toJson(),
      'lightRange': lightRange.toJson(),
    };
  }

  // 식물 종의 적정 조건 정보 문자열 생성
  String getOptimalConditionsText() {
    return '적정 환경 조건:\n'
        '온도: ${temperatureRange.min.toStringAsFixed(1)}-${temperatureRange.max.toStringAsFixed(1)}°C\n'
        '습도: ${humidityRange.min.toStringAsFixed(1)}-${humidityRange.max.toStringAsFixed(1)}%\n'
        '조도: ${lightRange.min.toInt()}-${lightRange.max.toInt()} lux';
  }
}