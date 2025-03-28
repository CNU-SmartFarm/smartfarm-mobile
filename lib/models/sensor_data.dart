class SensorData {
  final String id;
  final double temperature;  // 온도 (°C)
  final double humidity;     // 습도 (%)
  final double light;        // 조도 (lux)
  final DateTime timestamp;  // 타임스탬프

  SensorData({
    required this.id,
    required this.temperature,
    required this.humidity,
    required this.light,
    required this.timestamp,
  });

  // JSON에서 센서 데이터 객체 생성
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      temperature: json['temperature'].toDouble(),
      humidity: json['humidity'].toDouble(),
      light: json['light'].toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  // 센서 데이터 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'temperature': temperature,
      'humidity': humidity,
      'light': light,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}