class Plant {
  String id;
  String name;
  String species;
  String registeredDate;
  double optimalTempMin;
  double optimalTempMax;
  double optimalHumidityMin;
  double optimalHumidityMax;
  double optimalSoilMoistureMin;
  double optimalSoilMoistureMax;
  double optimalLightMin;
  double optimalLightMax;

  Plant({
    required this.id,
    required this.name,
    required this.species,
    required this.registeredDate,
    required this.optimalTempMin,
    required this.optimalTempMax,
    required this.optimalHumidityMin,
    required this.optimalHumidityMax,
    required this.optimalSoilMoistureMin,
    required this.optimalSoilMoistureMax,
    required this.optimalLightMin,
    required this.optimalLightMax,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      species: json['species'] ?? '',
      registeredDate: json['registeredDate'] ?? '',
      optimalTempMin: (json['optimalTempMin'] ?? 0).toDouble(),
      optimalTempMax: (json['optimalTempMax'] ?? 0).toDouble(),
      optimalHumidityMin: (json['optimalHumidityMin'] ?? 0).toDouble(),
      optimalHumidityMax: (json['optimalHumidityMax'] ?? 0).toDouble(),
      optimalSoilMoistureMin: (json['optimalSoilMoistureMin'] ?? 0).toDouble(),
      optimalSoilMoistureMax: (json['optimalSoilMoistureMax'] ?? 0).toDouble(),
      optimalLightMin: (json['optimalLightMin'] ?? 0).toDouble(),
      optimalLightMax: (json['optimalLightMax'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'registeredDate': registeredDate,
      'optimalTempMin': optimalTempMin,
      'optimalTempMax': optimalTempMax,
      'optimalHumidityMin': optimalHumidityMin,
      'optimalHumidityMax': optimalHumidityMax,
      'optimalSoilMoistureMin': optimalSoilMoistureMin,
      'optimalSoilMoistureMax': optimalSoilMoistureMax,
      'optimalLightMin': optimalLightMin,
      'optimalLightMax': optimalLightMax,
    };
  }

  Plant copyWith({
    String? id,
    String? name,
    String? species,
    String? registeredDate,
    double? optimalTempMin,
    double? optimalTempMax,
    double? optimalHumidityMin,
    double? optimalHumidityMax,
    double? optimalSoilMoistureMin,
    double? optimalSoilMoistureMax,
    double? optimalLightMin,
    double? optimalLightMax,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      registeredDate: registeredDate ?? this.registeredDate,
      optimalTempMin: optimalTempMin ?? this.optimalTempMin,
      optimalTempMax: optimalTempMax ?? this.optimalTempMax,
      optimalHumidityMin: optimalHumidityMin ?? this.optimalHumidityMin,
      optimalHumidityMax: optimalHumidityMax ?? this.optimalHumidityMax,
      optimalSoilMoistureMin: optimalSoilMoistureMin ?? this.optimalSoilMoistureMin,
      optimalSoilMoistureMax: optimalSoilMoistureMax ?? this.optimalSoilMoistureMax,
      optimalLightMin: optimalLightMin ?? this.optimalLightMin,
      optimalLightMax: optimalLightMax ?? this.optimalLightMax,
    );
  }
}