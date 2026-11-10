import 'dart:convert';

/// Configuration settings for JourneySDK
class JourneyConfig {
  /// Internal obfuscated default endpoint: https://pdfgenai.vercel.app
  static final String _defaultEndpoint =
      utf8.decode(base64.decode('aHR0cHM6Ly9wZGZnZW5haS52ZXJjZWwuYXBw'));

  /// Unique identifier of the app (e.g. 'contractly', 'cvcraft', 'pdf_scanner')
  final String appId;

  /// Base URL of the tracking server (defaults to internal obfuscated endpoint)
  final String baseUrl;

  /// Maximum events to buffer before auto-flushing to backend
  final int batchSize;

  /// Periodic flush interval (defaults to 30 seconds)
  final Duration flushInterval;

  /// Inactivity duration after which a new session is automatically spawned (default 30 mins)
  final Duration sessionTimeout;

  /// Enable debug logs to console
  final bool debugLogging;

  /// Custom HTTP headers to include with requests
  final Map<String, String>? customHeaders;

  JourneyConfig({
    required this.appId,
    String? baseUrl,
    this.batchSize = 20,
    this.flushInterval = const Duration(seconds: 30),
    this.sessionTimeout = const Duration(minutes: 30),
    this.debugLogging = false,
    this.customHeaders,
  }) : baseUrl = baseUrl ?? _defaultEndpoint;
}
