class HistoricalDataPoint {
  String id;
  String plantId;
  String date;
  int time;
  double temperature;
  double humidity;
  double soilMoisture;
  double light;

  HistoricalDataPoint({
    required this.id,
    required this.plantId,
    required this.date,
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.light,
  });

  factory HistoricalDataPoint.fromJson(Map<String, dynamic> json) {
    return HistoricalDataPoint(
      id: json['id'] ?? '',
      plantId: json['plantId'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? 0,
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      soilMoisture: (json['soilMoisture'] ?? 0).toDouble(),
      light: (json['light'] ?? 0).toDouble(),
    );
  }
}