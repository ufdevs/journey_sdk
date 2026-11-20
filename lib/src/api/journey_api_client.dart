import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/journey_config.dart';
import '../core/journey_logger.dart';
import '../core/time_utils.dart';
import '../models/session_record.dart';
import '../models/tracked_event.dart';

/// High-throughput HTTP client for batch event and session ingestion
class JourneyApiClient {
  final JourneyConfig config;
  final http.Client _client = http.Client();

  JourneyApiClient({required this.config});

  /// Sends a batch payload of events and session updates (with retries).
  Future<bool> sendBatch({
    required String deviceId,
    required SessionRecord session,
    required List<TrackedEvent> events,
    String? userId,
    String? userEmail,
    Map<String, dynamic>? userTraits,
  }) async {
    final endpoint = '${config.baseUrl}/api/journey/batch';
    final uri = Uri.parse(endpoint);

    final body = {
      'appId': config.appId,
      'deviceId': deviceId,
      'userId': userId ?? session.userId,
      'userEmail': userEmail ?? session.userEmail,
      'userTraits': userTraits ?? session.userTraits,
      'session': session.toJson(),
      'events': events.map((e) => e.toJson()).toList(),
      'sdk': {
        'name': 'journey_sdk',
        'version': JourneyConfig.sdkVersion,
        'timezone': TimeUtils.timezoneLabel(),
        'timezoneOffsetMinutes': TimeUtils.timezoneOffsetMinutes(),
        'locale': TimeUtils.localeTag(),
      },
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-app-id': config.appId,
      'x-sdk-name': 'journey_sdk',
      'x-sdk-version': JourneyConfig.sdkVersion,
      'x-device-id': deviceId,
      'x-timezone-offset': '${TimeUtils.timezoneOffsetMinutes()}',
      ...(config.customHeaders ?? {}),
    };

    final attempts = 1 + config.maxRetries.clamp(0, 5);
    Object? lastError;
    int? lastStatus;

    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        JourneyLogger.i(
          'Flush attempt $attempt/$attempts → $endpoint '
          '(events=${events.length}, session=${session.sessionId})',
        );

        final response = await _client
            .post(
              uri,
              headers: headers,
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 20));

        lastStatus = response.statusCode;

        if (response.statusCode >= 200 && response.statusCode < 300) {
          JourneyLogger.flush(
            eventCount: events.length,
            success: true,
            statusCode: response.statusCode,
          );
          return true;
        }

        // Don't retry permanent client errors (except 408/429)
        final retryable = response.statusCode == 408 ||
            response.statusCode == 429 ||
            response.statusCode >= 500;
        JourneyLogger.flush(
          eventCount: events.length,
          success: false,
          statusCode: response.statusCode,
          detail: response.body.length > 200
              ? '${response.body.substring(0, 200)}…'
              : response.body,
        );

        if (!retryable || attempt == attempts) {
          return false;
        }
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      } catch (e) {
        lastError = e;
        JourneyLogger.e('Network error on flush attempt $attempt/$attempts', e);
        if (attempt == attempts) {
          JourneyLogger.flush(
            eventCount: events.length,
            success: false,
            statusCode: lastStatus,
            detail: e.toString(),
          );
          return false;
        }
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }

    JourneyLogger.e('Batch ingest exhausted retries', lastError);
    return false;
  }

  void dispose() {
    _client.close();
  }
}