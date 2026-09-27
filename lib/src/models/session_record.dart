/// Represents a user or device app session lifecycle
class SessionRecord {
  final String sessionId;
  final String appId;
  final String deviceId;
  String? userId;
  String? userEmail;
  final DateTime startedAt;
  DateTime lastActiveAt;
  DateTime? endedAt;
  int durationSeconds;
  int eventsCount;
  String? entryScreen;
  String? exitScreen;
  Map<String, dynamic> deviceInfo;
  Map<String, dynamic> userTraits;
  String status; // 'active', 'completed', 'timed_out'

  SessionRecord({
    required this.sessionId,
    required this.appId,
    required this.deviceId,
    this.userId,
    this.userEmail,
    required this.startedAt,
    required this.lastActiveAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.eventsCount = 0,
    this.entryScreen,
    this.exitScreen,
    this.deviceInfo = const {},
    this.userTraits = const {},
    this.status = 'active',
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'appId': appId,
    'deviceId': deviceId,
    if (userId != null) 'userId': userId,
    if (userEmail != null) 'userEmail': userEmail,
    'startedAt': startedAt.toIso8601String(),
    'lastActiveAt': lastActiveAt.toIso8601String(),
    if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
    'durationSeconds': durationSeconds,
    'eventsCount': eventsCount,
    if (entryScreen != null) 'entryScreen': entryScreen,
    if (exitScreen != null) 'exitScreen': exitScreen,
    'deviceInfo': deviceInfo,
    'userTraits': userTraits,
    'status': status,
  };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
    sessionId: json['sessionId'] as String,
    appId: json['appId'] as String,
    deviceId: json['deviceId'] as String,
    userId: json['userId'] as String?,
    userEmail: json['userEmail'] as String?,
    startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
    lastActiveAt: DateTime.tryParse(json['lastActiveAt'] as String? ?? '') ?? DateTime.now(),
    endedAt: json['endedAt'] != null ? DateTime.tryParse(json['endedAt'] as String) : null,
    durationSeconds: json['durationSeconds'] as int? ?? 0,
    eventsCount: json['eventsCount'] as int? ?? 0,
    entryScreen: json['entryScreen'] as String?,
    exitScreen: json['exitScreen'] as String?,
    deviceInfo: Map<String, dynamic>.from(json['deviceInfo'] as Map? ?? {}),
    userTraits: Map<String, dynamic>.from(json['userTraits'] as Map? ?? {}),
    status: json['status'] as String? ?? 'active',
  );
}
