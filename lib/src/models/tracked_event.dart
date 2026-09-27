/// Represents an analytical event inside a user/device session
class TrackedEvent {
  final String id;
  final String appId;
  final String sessionId;
  final int seqNo;
  final String deviceId;
  final String? userId;
  final String? userEmail;
  final String eventType;
  final String eventName;
  final Map<String, dynamic> payload;
  final String? contractId;
  final String? templateId;
  final DateTime timestamp;
  final String source;

  TrackedEvent({
    required this.id,
    required this.appId,
    required this.sessionId,
    required this.seqNo,
    required this.deviceId,
    this.userId,
    this.userEmail,
    required this.eventType,
    required this.eventName,
    this.payload = const {},
    this.contractId,
    this.templateId,
    required this.timestamp,
    this.source = 'journey_sdk',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'appId': appId,
    'sessionId': sessionId,
    'seqNo': seqNo,
    'deviceId': deviceId,
    if (userId != null) 'userId': userId,
    if (userEmail != null) 'userEmail': userEmail,
    'eventType': eventType,
    'eventName': eventName,
    'payload': payload,
    if (contractId != null) 'contractId': contractId,
    if (templateId != null) 'templateId': templateId,
    'timestamp': timestamp.toIso8601String(),
    'source': source,
  };

  factory TrackedEvent.fromJson(Map<String, dynamic> json) => TrackedEvent(
    id: json['id'] as String,
    appId: json['appId'] as String,
    sessionId: json['sessionId'] as String,
    seqNo: json['seqNo'] as int? ?? 1,
    deviceId: json['deviceId'] as String,
    userId: json['userId'] as String?,
    userEmail: json['userEmail'] as String?,
    eventType: json['eventType'] as String? ?? 'custom',
    eventName: json['eventName'] as String? ?? 'unnamed_event',
    payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
    contractId: json['contractId'] as String?,
    templateId: json['templateId'] as String?,
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    source: json['source'] as String? ?? 'journey_sdk',
  );
}
