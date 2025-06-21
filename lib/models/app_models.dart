export 'plant.dart';

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

class NotificationItem {
  int id;
  String plantId;
  String type;
  String message;
  DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.plantId,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      plantId: json['plantId'] ?? '',
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] == 1 || json['isRead'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plantId': plantId,
      'type': type,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  NotificationItem copyWith({
    int? id,
    String? plantId,
    String? type,
    String? message,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      type: type ?? this.type,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plantId': plantId,
      'date': date,
      'time': time,
      'temperature': temperature,
      'humidity': humidity,
      'soilMoisture': soilMoisture,
      'light': light,
    };
  }
}

class Settings {
  String userId;
  bool pushNotificationEnabled;
  String language;
  String theme;

  Settings({
    required this.userId,
    required this.pushNotificationEnabled,
    required this.language,
    required this.theme,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      userId: json['userId'] ?? '',
      pushNotificationEnabled: json['pushNotificationEnabled'] == 1 || json['pushNotificationEnabled'] == true,
      language: json['language'] ?? 'ko',
      theme: json['theme'] ?? 'light',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'pushNotificationEnabled': pushNotificationEnabled,
      'language': language,
      'theme': theme,
    };
  }

  Settings copyWith({
    String? userId,
    bool? pushNotificationEnabled,
    String? language,
    String? theme,
  }) {
    return Settings(
      userId: userId ?? this.userId,
      pushNotificationEnabled: pushNotificationEnabled ?? this.pushNotificationEnabled,
      language: language ?? this.language,
      theme: theme ?? this.theme,
    );
  }
}

class PlantProfile {
  String species;
  String commonName;
  double optimalTempMin;
  double optimalTempMax;
  double optimalHumidityMin;
  double optimalHumidityMax;
  double optimalSoilMoistureMin;
  double optimalSoilMoistureMax;
  double optimalLightMin;
  double optimalLightMax;
  String description;

  PlantProfile({
    required this.species,
    required this.commonName,
    required this.optimalTempMin,
    required this.optimalTempMax,
    required this.optimalHumidityMin,
    required this.optimalHumidityMax,
    required this.optimalSoilMoistureMin,
    required this.optimalSoilMoistureMax,
    required this.optimalLightMin,
    required this.optimalLightMax,
    required this.description,
  });

  factory PlantProfile.fromJson(Map<String, dynamic> json) {
    return PlantProfile(
      species: json['species'] ?? '',
      commonName: json['commonName'] ?? '',
      optimalTempMin: (json['optimalTempMin'] ?? 0).toDouble(),
      optimalTempMax: (json['optimalTempMax'] ?? 0).toDouble(),
      optimalHumidityMin: (json['optimalHumidityMin'] ?? 0).toDouble(),
      optimalHumidityMax: (json['optimalHumidityMax'] ?? 0).toDouble(),
      optimalSoilMoistureMin: (json['optimalSoilMoistureMin'] ?? 0).toDouble(),
      optimalSoilMoistureMax: (json['optimalSoilMoistureMax'] ?? 0).toDouble(),
      optimalLightMin: (json['optimalLightMin'] ?? 0).toDouble(),
      optimalLightMax: (json['optimalLightMax'] ?? 0).toDouble(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'species': species,
      'commonName': commonName,
      'optimalTempMin': optimalTempMin,
      'optimalTempMax': optimalTempMax,
      'optimalHumidityMin': optimalHumidityMin,
      'optimalHumidityMax': optimalHumidityMax,
      'optimalSoilMoistureMin': optimalSoilMoistureMin,
      'optimalSoilMoistureMax': optimalSoilMoistureMax,
      'optimalLightMin': optimalLightMin,
      'optimalLightMax': optimalLightMax,
      'description': description,
    };
  }
}

class AIIdentificationResult {
  String species;
  double confidence;
  String suggestedName;
  Map<String, double> optimalSettings;

  AIIdentificationResult({
    required this.species,
    required this.confidence,
    required this.suggestedName,
    required this.optimalSettings,
  });

  factory AIIdentificationResult.fromJson(Map<String, dynamic> json) {
    return AIIdentificationResult(
      species: json['species'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      suggestedName: json['suggestedName'] ?? '',
      optimalSettings: Map<String, double>.from(
        json['optimalSettings']?.map((key, value) => MapEntry(key, (value ?? 0).toDouble())) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'species': species,
      'confidence': confidence,
      'suggestedName': suggestedName,
      'optimalSettings': optimalSettings,
    };
  }
}