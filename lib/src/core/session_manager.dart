import 'package:uuid/uuid.dart';
import '../config/journey_config.dart';
import '../models/session_record.dart';
import '../storage/hive_event_queue.dart';
import 'device_identifier.dart';
import 'time_utils.dart';

/// Manages session lifecycle, rotation on timeouts, and sequential event numbering
class SessionManager {
  final JourneyConfig config;
  SessionRecord? _currentSession;
  int _sequenceCounter = 0;

  SessionManager({required this.config});

  /// Initialize or resume session
  Future<SessionRecord> initializeSession({required String deviceId}) async {
    final persisted = HiveEventQueue.getActiveSession();
    final now = TimeUtils.utcNow();

    if (persisted != null) {
      final lastActive = persisted.lastActiveAt.toUtc();
      final inactivity = now.difference(lastActive);
      if (inactivity < config.sessionTimeout && persisted.status == 'active') {
        // Resume existing active session
        persisted.lastActiveAt = now;
        _currentSession = persisted;
        _sequenceCounter = persisted.eventsCount;
        await HiveEventQueue.saveActiveSession(persisted);
        return persisted;
      } else {
        // Mark old session as completed or timed out
        persisted.endedAt = persisted.lastActiveAt;
        persisted.status = 'timed_out';
        await HiveEventQueue.saveActiveSession(persisted);
      }
    }

    // Spawn new session
    return await startNewSession(deviceId: deviceId);
  }

  /// Start a brand new session
  Future<SessionRecord> startNewSession({required String deviceId, String? entryScreen}) async {
    final now = TimeUtils.utcNow();
    final deviceInfo = await DeviceIdentifier.collectDeviceInfo();
    final userId = HiveEventQueue.getSavedUserId();
    final userEmail = HiveEventQueue.getSavedUserEmail();
    final userTraits = HiveEventQueue.getSavedUserTraits() ?? {};

    final newSession = SessionRecord(
      sessionId: 'sess_${const Uuid().v4().replaceAll('-', '').substring(0, 16)}',
      appId: config.appId,
      deviceId: deviceId,
      userId: userId,
      userEmail: userEmail,
      startedAt: now,
      lastActiveAt: now,
      entryScreen: entryScreen,
      deviceInfo: deviceInfo,
      userTraits: userTraits,
      status: 'active',
      eventsCount: 0,
    );

    _currentSession = newSession;
    _sequenceCounter = 0;
    await HiveEventQueue.saveActiveSession(newSession);
    return newSession;
  }

  /// Check if session has expired and rotate if needed
  Future<SessionRecord> ensureActiveSession({required String deviceId, String? currentScreen}) async {
    final now = TimeUtils.utcNow();
    if (_currentSession == null) {
      return await initializeSession(deviceId: deviceId);
    }

    // Completed/timed_out sessions must not be reused
    if (_currentSession!.status != 'active') {
      return await startNewSession(deviceId: deviceId, entryScreen: currentScreen);
    }

    final inactivity = now.difference(_currentSession!.lastActiveAt.toUtc());
    if (inactivity >= config.sessionTimeout) {
      // Inactivity timeout -> end current session and start fresh
      _currentSession!.endedAt = _currentSession!.lastActiveAt;
      _currentSession!.status = 'timed_out';
      await HiveEventQueue.saveActiveSession(_currentSession!);

      return await startNewSession(deviceId: deviceId, entryScreen: currentScreen);
    }

    // Update active timestamp and duration
    _currentSession!.lastActiveAt = now;
    _currentSession!.durationSeconds =
        now.difference(_currentSession!.startedAt.toUtc()).inSeconds;
    if (currentScreen != null) {
      _currentSession!.exitScreen = currentScreen;
    }
    await HiveEventQueue.saveActiveSession(_currentSession!);
    return _currentSession!;
  }

  /// Next event sequence number
  int nextSequenceNumber() {
    _sequenceCounter++;
    if (_currentSession != null) {
      _currentSession!.eventsCount = _sequenceCounter;
      HiveEventQueue.saveActiveSession(_currentSession!);
    }
    return _sequenceCounter;
  }

  /// Current session record
  SessionRecord? get currentSession => _currentSession;

  /// Update user identity attached to active session
  Future<void> attachUserIdentity({String? userId, String? email, Map<String, dynamic>? traits}) async {
    if (_currentSession != null) {
      if (userId != null) _currentSession!.userId = userId;
      if (email != null) _currentSession!.userEmail = email;
      if (traits != null) _currentSession!.userTraits = {..._currentSession!.userTraits, ...traits};
      await HiveEventQueue.saveActiveSession(_currentSession!);
    }
  }

  /// Touch session while backgrounding (do NOT complete — timeout owns rotation).
  Future<void> touchSession() async {
    if (_currentSession != null && _currentSession!.status == 'active') {
      final now = TimeUtils.utcNow();
      _currentSession!.lastActiveAt = now;
      _currentSession!.durationSeconds =
          now.difference(_currentSession!.startedAt.toUtc()).inSeconds;
      await HiveEventQueue.saveActiveSession(_currentSession!);
    }
  }

  /// Mark session as completed (app detach / explicit end).
  Future<void> endSession() async {
    if (_currentSession != null && _currentSession!.status == 'active') {
      final now = TimeUtils.utcNow();
      _currentSession!.endedAt = now;
      _currentSession!.lastActiveAt = now;
      _currentSession!.durationSeconds =
          now.difference(_currentSession!.startedAt.toUtc()).inSeconds;
      _currentSession!.status = 'completed';
      await HiveEventQueue.saveActiveSession(_currentSession!);
    }
  }
}
