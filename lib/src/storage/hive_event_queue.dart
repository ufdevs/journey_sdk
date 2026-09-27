import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/session_record.dart';
import '../models/tracked_event.dart';

/// Blazing fast, crash-resilient Hive storage box for events and session state
class HiveEventQueue {
  static const String _eventsBoxName = 'journey_sdk_events_v1';
  static const String _sessionBoxName = 'journey_sdk_session_v1';
  static const String _metaBoxName = 'journey_sdk_meta_v1';

  static Box<String>? _eventsBox;
  static Box<String>? _sessionBox;
  static Box<dynamic>? _metaBox;

  /// Initialize Hive storage boxes
  static Future<void> init() async {
    await Hive.initFlutter();
    _eventsBox = await Hive.openBox<String>(_eventsBoxName);
    _sessionBox = await Hive.openBox<String>(_sessionBoxName);
    _metaBox = await Hive.openBox<dynamic>(_metaBoxName);
  }

  // ── Device ID & Identity Storage ───────────────────────────────────────────

  static String? getSavedDeviceId() => _metaBox?.get('deviceId') as String?;
  static Future<void> saveDeviceId(String deviceId) async => await _metaBox?.put('deviceId', deviceId);

  static String? getSavedUserId() => _metaBox?.get('userId') as String?;
  static String? getSavedUserEmail() => _metaBox?.get('userEmail') as String?;
  static Map<String, dynamic>? getSavedUserTraits() {
    final raw = _metaBox?.get('userTraits');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static Future<void> saveUserIdentity({String? userId, String? email, Map<String, dynamic>? traits}) async {
    if (userId != null) await _metaBox?.put('userId', userId);
    if (email != null) await _metaBox?.put('userEmail', email);
    if (traits != null) await _metaBox?.put('userTraits', traits);
  }

  static Future<void> clearUserIdentity() async {
    await _metaBox?.delete('userId');
    await _metaBox?.delete('userEmail');
    await _metaBox?.delete('userTraits');
  }

  // ── Event Queue Operations ─────────────────────────────────────────────────

  /// Add tracked event to persistent queue
  static Future<void> enqueueEvent(TrackedEvent event) async {
    try {
      final jsonStr = jsonEncode(event.toJson());
      await _eventsBox?.put(event.id, jsonStr);
    } catch (e) {
      debugPrint('[JourneySDK] Hive enqueue error: $e');
    }
  }

  /// Peek up to [limit] events from the queue
  static List<TrackedEvent> peekEvents({int limit = 20}) {
    if (_eventsBox == null || _eventsBox!.isEmpty) return [];

    final result = <TrackedEvent>[];
    final values = _eventsBox!.values.toList();
    final count = values.length > limit ? limit : values.length;

    for (int i = 0; i < count; i++) {
      try {
        final map = jsonDecode(values[i]) as Map<String, dynamic>;
        result.add(TrackedEvent.fromJson(map));
      } catch (_) {}
    }
    return result;
  }

  /// Remove specific events from queue after successful server ingestion
  static Future<void> removeEvents(List<String> eventIds) async {
    if (_eventsBox == null) return;
    try {
      await _eventsBox!.deleteAll(eventIds);
    } catch (e) {
      debugPrint('[JourneySDK] Hive delete error: $e');
    }
  }

  /// Count pending events
  static int get pendingEventsCount => _eventsBox?.length ?? 0;

  // ── Session State Persistence ──────────────────────────────────────────────

  static SessionRecord? getActiveSession() {
    final raw = _sessionBox?.get('current_session');
    if (raw == null) return null;
    try {
      return SessionRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveActiveSession(SessionRecord session) async {
    try {
      await _sessionBox?.put('current_session', jsonEncode(session.toJson()));
    } catch (e) {
      debugPrint('[JourneySDK] Hive session save error: $e');
    }
  }

  static Future<void> clearActiveSession() async {
    await _sessionBox?.delete('current_session');
  }
}
