import 'package:flutter/foundation.dart';

@immutable
abstract class JourneyEvent {}

/// Enqueue a new analytical event
class TrackEventRequested extends JourneyEvent {
  final String eventType;
  final String eventName;
  final Map<String, dynamic> payload;
  final String? contractId;
  final String? templateId;
  final DateTime? timestamp;

  TrackEventRequested({
    required this.eventType,
    required this.eventName,
    this.payload = const {},
    this.contractId,
    this.templateId,
    this.timestamp,
  });
}

/// Screen view transition
class ScreenViewRequested extends JourneyEvent {
  final String screenName;
  final String? previousScreenName;
  final Map<String, dynamic> metadata;

  ScreenViewRequested({
    required this.screenName,
    this.previousScreenName,
    this.metadata = const {},
  });
}

/// Trigger periodic or forced flush of pending events
class FlushQueueRequested extends JourneyEvent {
  final bool isForced;
  FlushQueueRequested({this.isForced = false});
}

/// Identify user profile
class IdentifyUserRequested extends JourneyEvent {
  final String userId;
  final String? email;
  final Map<String, dynamic> traits;

  IdentifyUserRequested({
    required this.userId,
    this.email,
    this.traits = const {},
  });
}

/// Reset identity on logout
class ResetIdentityRequested extends JourneyEvent {}

/// App lifecycle state change (e.g. backgrounded or resumed)
class AppLifecycleChanged extends JourneyEvent {
  final String lifecycleState; // 'resumed', 'paused', 'inactive', 'detached'

  AppLifecycleChanged({required this.lifecycleState});
}
