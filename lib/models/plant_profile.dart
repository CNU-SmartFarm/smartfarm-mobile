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