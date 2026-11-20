import 'dart:ui' show PlatformDispatcher;

/// UTC-first time helpers so international apps store comparable timestamps.
///
/// Flutter `DateTime.now().toIso8601String()` emits local time WITHOUT an offset
/// (e.g. `2026-11-20T23:10:00.000` in India). Node/Mongo often treat that as UTC,
/// shifting displayed times by +5:30 for IST users. Always send UTC with a trailing `Z`.
class TimeUtils {
  TimeUtils._();

  /// Current instant in UTC.
  static DateTime utcNow() => DateTime.now().toUtc();

  /// Serialize any DateTime as UTC ISO-8601 with `Z` (e.g. `2026-11-20T17:40:00.000Z`).
  static String toUtcIso8601(DateTime value) {
    final utc = value.isUtc ? value : value.toUtc();
    return utc.toIso8601String();
  }

  /// Minutes east of UTC (India = 330). Negated Dart `timeZoneOffset` sign is not needed:
  /// `DateTime.now().timeZoneOffset.inMinutes` is already +330 for IST.
  static int timezoneOffsetMinutes() => DateTime.now().timeZoneOffset.inMinutes;

  /// Best-effort IANA-ish / locale timezone label for analytics (not always full IANA).
  static String timezoneLabel() {
    final offset = timezoneOffsetMinutes();
    final sign = offset >= 0 ? '+' : '-';
    final abs = offset.abs();
    final hours = (abs ~/ 60).toString().padLeft(2, '0');
    final mins = (abs % 60).toString().padLeft(2, '0');
    return 'UTC$sign$hours:$mins';
  }

  static String localeTag() {
    try {
      return PlatformDispatcher.instance.locale.toLanguageTag();
    } catch (_) {
      return 'und';
    }
  }

  /// Metadata to attach on sessions / deviceInfo for correct admin display.
  static Map<String, dynamic> timezoneContext() => {
        'timezoneOffsetMinutes': timezoneOffsetMinutes(),
        'timezone': timezoneLabel(),
        'locale': localeTag(),
        'timestampUtc': toUtcIso8601(utcNow()),
      };
}