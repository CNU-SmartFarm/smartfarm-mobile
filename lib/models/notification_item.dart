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

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      plantId: plantId,
      type: type,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}