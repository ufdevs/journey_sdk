import 'dart:convert';

/// Configuration settings for JourneySDK
class JourneyConfig {
  /// Shared production backend — all UFDevs apps send journey data here.
  /// Endpoint: POST `{baseUrl}/api/journey/batch`
  static const String defaultBaseUrl = 'https://pdfgenai.vercel.app';

  /// Package version sent as `x-sdk-version` for diagnostics.
  static const String sdkVersion = '1.1.0';

  /// Obfuscated fallback (same as [defaultBaseUrl]).
  static final String _defaultEndpoint =
      utf8.decode(base64.decode('aHR0cHM6Ly9wZGZnZW5haS52ZXJjZWwuYXBw'));

  /// Unique identifier of the app (lowercase slug: 'contractly', 'cvcraft', 'photogpt')
  final String appId;

  /// Base URL of the tracking server (defaults to shared production backend)
  final String baseUrl;

  /// Maximum events to buffer before auto-flushing to backend
  final int batchSize;

  /// Periodic flush interval (defaults to 30 seconds)
  final Duration flushInterval;

  /// Inactivity duration after which a new session is automatically spawned (default 30 mins)
  final Duration sessionTimeout;

  /// Enable debug logs to console
  final bool debugLogging;

  /// How many times to retry a failed batch flush
  final int maxRetries;

  /// Custom HTTP headers to include with requests
  final Map<String, String>? customHeaders;

  JourneyConfig({
    required String appId,
    String? baseUrl,
    this.batchSize = 20,
    this.flushInterval = const Duration(seconds: 30),
    this.sessionTimeout = const Duration(minutes: 30),
    this.debugLogging = false,
    this.maxRetries = 2,
    this.customHeaders,
  })  : appId = normalizeAppId(appId),
        baseUrl = _normalizeBaseUrl(baseUrl ?? _defaultEndpoint);

  /// Normalize app ids so analytics filters stay consistent across apps.
  static String normalizeAppId(String raw) {
    var value = raw.trim().toLowerCase();
    if (value.isEmpty) return 'app';
    // Common typos / aliases
    if (value == 'phtotgpt' || value == 'photo_gpt' || value == 'photo-gpt') {
      value = 'photogpt';
    }
    if (value == 'cv_craft' || value == 'cv-craft') {
      value = 'cvcraft';
    }
    return value.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
  }

  static String _normalizeBaseUrl(String url) {
    var value = url.trim();
    if (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}