class SensorData {
  String id;
  String plantId;
  double temperature;
  double humidity;
  double soilMoisture;
  double light;
  DateTime timestamp;

  SensorData({
    required this.id,
    required this.plantId,
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.light,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      id: json['id'] ?? '',
      plantId: json['plantId'] ?? '',
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      soilMoisture: (json['soilMoisture'] ?? 0).toDouble(),
      light: (json['light'] ?? 0).toDouble(),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plantId': plantId,
      'temperature': temperature,
      'humidity': humidity,
      'soilMoisture': soilMoisture,
      'light': light,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}