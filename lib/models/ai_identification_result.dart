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
    final settings = json['optimalSettings'] ?? {};
    return AIIdentificationResult(
      species: json['species'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      suggestedName: json['suggestedName'] ?? '',
      optimalSettings: Map<String, double>.from(
        settings.map((key, value) => MapEntry(key, (value ?? 0).toDouble())),
      ),
    );
  }
}