import 'package:flutter/foundation.dart';

/// Centralized JourneySDK logger. Enabled when [enabled] is true (usually debugLogging).
class JourneyLogger {
  JourneyLogger._();

  static bool enabled = false;
  static String appId = 'app';

  static void configure({required bool debugLogging, required String appId}) {
    enabled = debugLogging;
    JourneyLogger.appId = appId;
  }

  static void i(String message) {
    if (!enabled) return;
    debugPrint('[JourneySDK:$appId] $message');
  }

  static void w(String message) {
    if (!enabled) return;
    debugPrint('[JourneySDK:$appId][WARN] $message');
  }

  static void e(String message, [Object? error]) {
    // Errors always print in debug builds so silent ingest failures are visible
    if (!enabled && !kDebugMode) return;
    final suffix = error != null ? ' | $error' : '';
    debugPrint('[JourneySDK:$appId][ERROR] $message$suffix');
  }

  static void event({
    required String eventType,
    required String eventName,
    required String sessionId,
    required int seqNo,
    Map<String, dynamic>? payload,
  }) {
    if (!enabled) return;
    final keys = payload == null || payload.isEmpty
        ? ''
        : ' keys=${payload.keys.take(8).join(',')}';
    debugPrint(
      '[JourneySDK:$appId][EVENT] type=$eventType name=$eventName '
      'seq=$seqNo session=${sessionId.substring(0, sessionId.length.clamp(0, 12))}…$keys',
    );
  }

  static void flush({
    required int eventCount,
    required bool success,
    int? statusCode,
    String? detail,
  }) {
    if (!enabled) return;
    final status = success ? 'OK' : 'FAIL';
    final code = statusCode != null ? ' http=$statusCode' : '';
    final extra = detail != null && detail.isNotEmpty ? ' $detail' : '';
    debugPrint('[JourneySDK:$appId][FLUSH] $status events=$eventCount$code$extra');
  }
}