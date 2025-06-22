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
    bool? pushNotificationEnabled,
    String? language,
    String? theme,
  }) {
    return Settings(
      userId: userId,
      pushNotificationEnabled: pushNotificationEnabled ?? this.pushNotificationEnabled,
      language: language ?? this.language,
      theme: theme ?? this.theme,
    );
  }
}