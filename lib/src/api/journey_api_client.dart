import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/journey_config.dart';
import '../models/session_record.dart';
import '../models/tracked_event.dart';

/// High-throughput HTTP client for batch event and session ingestion
class JourneyApiClient {
  final JourneyConfig config;
  final http.Client _client = http.Client();

  JourneyApiClient({required this.config});

  /// Sends a batch payload of events and session updates
  Future<bool> sendBatch({
    required String deviceId,
    required SessionRecord session,
    required List<TrackedEvent> events,
    String? userId,
    String? userEmail,
    Map<String, dynamic>? userTraits,
  }) async {
    try {
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
      };

      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-app-id': config.appId,
              ...(config.customHeaders ?? {}),
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (config.debugLogging) {
          debugPrint('[JourneySDK] Batch of ${events.length} events successfully ingested.');
        }
        return true;
      } else {
        if (config.debugLogging) {
          debugPrint('[JourneySDK] Batch ingest failed (${response.statusCode}): ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (config.debugLogging) {
        debugPrint('[JourneySDK] Network or batch error: $e');
      }
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
