import 'package:flutter/foundation.dart';
import '../models/session_record.dart';

@immutable
class JourneyState {
  final String deviceId;
  final SessionRecord? currentSession;
  final int pendingEventsCount;
  final bool isFlushing;
  final String? lastError;
  final String? activeScreen;

  const JourneyState({
    required this.deviceId,
    this.currentSession,
    this.pendingEventsCount = 0,
    this.isFlushing = false,
    this.lastError,
    this.activeScreen,
  });

  JourneyState copyWith({
    String? deviceId,
    SessionRecord? currentSession,
    int? pendingEventsCount,
    bool? isFlushing,
    String? lastError,
    String? activeScreen,
  }) {
    return JourneyState(
      deviceId: deviceId ?? this.deviceId,
      currentSession: currentSession ?? this.currentSession,
      pendingEventsCount: pendingEventsCount ?? this.pendingEventsCount,
      isFlushing: isFlushing ?? this.isFlushing,
      lastError: lastError,
      activeScreen: activeScreen ?? this.activeScreen,
    );
  }
}
